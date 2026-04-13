# Databricks notebook source
"""
Gold Layer: Data Aggregation
Read Silver curated data, aggregate by category, write to Gold UC table.
"""

from pyspark.sql import functions as F
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# PARAMETERS (injected by DAB job)
# ============================================================================

dbutils.widgets.text("source_catalog", "blg_silver", "Source Catalog (Silver)")
dbutils.widgets.text("source_schema", "curated_data", "Source Schema (Silver)")
dbutils.widgets.text("target_catalog", "blg_gold", "Target Catalog (Gold)")
dbutils.widgets.text("target_schema", "analytics", "Target Schema (Gold)")

source_catalog = dbutils.widgets.get("source_catalog")
source_schema = dbutils.widgets.get("source_schema")
target_catalog = dbutils.widgets.get("target_catalog")
target_schema = dbutils.widgets.get("target_schema")

logger.info(f"Starting Gold aggregation: {source_catalog}.{source_schema} → {target_catalog}.{target_schema}")

# ============================================================================
# READ FROM SILVER
# ============================================================================

# Discover tables in Silver schema
silver_tables = spark.sql(f"SHOW TABLES IN {source_catalog}.{source_schema}") \
    .filter(~F.col("tableName").like("_%")) \
    .select("tableName") \
    .collect()

if not silver_tables:
    raise Exception(f"No tables found in {source_catalog}.{source_schema}")

source_table_name = silver_tables[0]["tableName"]
source_full_name = f"{source_catalog}.{source_schema}.{source_table_name}"

logger.info(f"Reading source table: {source_full_name}")

try:
    silver_df = spark.table(source_full_name)
    logger.info(f"Read {silver_df.count()} rows from {source_full_name}")
except Exception as e:
    logger.error(f"Failed to read Silver table: {e}")
    raise

# ============================================================================
# AGGREGATION: GROUP BY CATEGORY, SUM METRICS
# ============================================================================

# Detect numeric columns for aggregation (sum, avg, count)
numeric_cols = [field.name for field in silver_df.schema.fields if field.dataType.typeName() in ["integer", "long", "double", "decimal"]]

# Assume 'category' column exists; adjust as needed
category_col = "category" if "category" in silver_df.columns else silver_df.columns[0]

if not numeric_cols:
    logger.warning("No numeric columns found for aggregation; applying basic GROUP BY")
    gold_df = silver_df \
        .groupBy(category_col) \
        .agg(F.count("*").alias("record_count"))
else:
    try:
        agg_expr = {col: "sum" for col in numeric_cols}
        agg_expr["*"] = "count"
        
        gold_df = silver_df \
            .groupBy(category_col) \
            .agg(
                F.count("*").alias("record_count"),
                **{col: F.sum(col).alias(f"{col}_sum") for col in numeric_cols},
                **{col: F.avg(col).alias(f"{col}_avg") for col in numeric_cols}
            )
        
        logger.info(f"Aggregated by {category_col}: {gold_df.count()} groups")
        
    except Exception as e:
        logger.error(f"Aggregation failed: {e}")
        raise

# Add aggregation metadata
gold_df = gold_df \
    .withColumn("_gold_timestamp", F.current_timestamp()) \
    .withColumn("_aggregation_date", F.current_date())

# ============================================================================
# WRITE TO GOLD MANAGED TABLE
# ============================================================================

target_table_name = f"{source_table_name}_agg"  # Add _agg suffix for aggregated tables
target_full_name = f"{target_catalog}.{target_schema}.{target_table_name}"

try:
    gold_df \
        .write \
        .format("delta") \
        .mode("overwrite") \
        .option("mergeSchema", "true") \
        .saveAsTable(target_full_name)
    
    logger.info(f"Successfully wrote {gold_df.count()} rows to {target_full_name}")
    
except Exception as e:
    logger.error(f"Failed to write to Gold table: {e}")
    raise

# ============================================================================
# RECORD AGGREGATION METADATA
# ============================================================================

metadata_df = spark.createDataFrame(
    [
        {
            "log_date": datetime.utcnow().isoformat(),
            "layer": "gold",
            "source_table": source_full_name,
            "target_table": target_full_name,
            "source_row_count": silver_df.count(),
            "target_row_count": gold_df.count(),
            "aggregation_key": category_col,
            "status": "SUCCESS"
        }
    ]
)

metadata_table = f"{target_catalog}.{target_schema}._aggregation_log"
try:
    metadata_df \
        .write \
        .format("delta") \
        .mode("append") \
        .option("mergeSchema", "true") \
        .saveAsTable(metadata_table)
    logger.info(f"Recorded aggregation log to {metadata_table}")
except Exception as e:
    logger.warning(f"Failed to record metadata (non-fatal): {e}")

print(f"✓ Gold aggregation completed: {target_full_name}")
