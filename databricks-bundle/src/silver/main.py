# Databricks notebook source
"""
Silver Layer: Data Transformation
Read Bronze raw data, deduplicate, filter nulls, write to Silver UC table.
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

dbutils.widgets.text("source_catalog", "blg_bronze", "Source Catalog (Bronze)")
dbutils.widgets.text("source_schema", "raw_data", "Source Schema (Bronze)")
dbutils.widgets.text("target_catalog", "blg_silver", "Target Catalog (Silver)")
dbutils.widgets.text("target_schema", "curated_data", "Target Schema (Silver)")

source_catalog = dbutils.widgets.get("source_catalog")
source_schema = dbutils.widgets.get("source_schema")
target_catalog = dbutils.widgets.get("target_catalog")
target_schema = dbutils.widgets.get("target_schema")

logger.info(f"Starting Silver transform: {source_catalog}.{source_schema} → {target_catalog}.{target_schema}")

# ============================================================================
# READ FROM BRONZE
# ============================================================================

# Discover tables in Bronze schema (excluding metadata tables)
bronze_tables = spark.sql(f"SHOW TABLES IN {source_catalog}.{source_schema}") \
    .filter(~F.col("tableName").like("_%")) \
    .select("tableName") \
    .collect()

if not bronze_tables:
    raise Exception(f"No tables found in {source_catalog}.{source_schema}")

source_table_name = bronze_tables[0]["tableName"]
source_full_name = f"{source_catalog}.{source_schema}.{source_table_name}"

logger.info(f"Reading source table: {source_full_name}")

try:
    bronze_df = spark.table(source_full_name)
    logger.info(f"Read {bronze_df.count()} rows from {source_full_name}")
except Exception as e:
    logger.error(f"Failed to read Bronze table: {e}")
    raise

# ============================================================================
# TRANSFORMATION: DEDUP & FILTER NULLS
# ============================================================================

# Assume 'source_id' is the primary key for deduplication
# If source_id doesn't exist, adjust to your actual key

try:
    if "source_id" in bronze_df.columns:
        # Dedup on source_id (keep latest by insertion order)
        silver_df = bronze_df \
            .withColumn("_row_num", F.row_number().over(
                F.Window.partitionBy("source_id").orderBy(F.desc("_load_timestamp"))
            )) \
            .filter(F.col("_row_num") == 1) \
            .drop("_row_num")
        logger.info(f"Deduplicated on source_id: {silver_df.count()} rows")
    else:
        silver_df = bronze_df
        logger.warning("Column 'source_id' not found; skipping deduplication")
    
    # Filter rows where all values are null (data quality check)
    non_null_cols = [col for col in silver_df.columns if col not in ["_load_timestamp"]]
    silver_df = silver_df.filter(
        ~F.lit(True).isin([F.col(col).isNull() for col in non_null_cols])
    )
    logger.info(f"Filtered nulls: {silver_df.count()} rows remaining")
    
    # Add transformation metadata
    silver_df = silver_df \
        .withColumn("_silver_timestamp", F.current_timestamp()) \
        .withColumn("_transformation_version", F.lit("1.0"))
    
except Exception as e:
    logger.error(f"Transformation failed: {e}")
    raise

# ============================================================================
# WRITE TO SILVER MANAGED TABLE
# ============================================================================

target_table_name = source_table_name  # Use same base name across layers
target_full_name = f"{target_catalog}.{target_schema}.{target_table_name}"

try:
    silver_df \
        .write \
        .format("delta") \
        .mode("overwrite") \
        .option("mergeSchema", "true") \
        .saveAsTable(target_full_name)
    
    logger.info(f"Successfully wrote {silver_df.count()} rows to {target_full_name}")
    
except Exception as e:
    logger.error(f"Failed to write to Silver table: {e}")
    raise

# ============================================================================
# RECORD TRANSFORMATION METADATA
# ============================================================================

metadata_df = spark.createDataFrame(
    [
        {
            "log_date": datetime.utcnow().isoformat(),
            "layer": "silver",
            "source_table": source_full_name,
            "target_table": target_full_name,
            "source_row_count": bronze_df.count(),
            "target_row_count": silver_df.count(),
            "status": "SUCCESS"
        }
    ]
)

metadata_table = f"{target_catalog}.{target_schema}._transform_log"
try:
    metadata_df \
        .write \
        .format("delta") \
        .mode("append") \
        .option("mergeSchema", "true") \
        .saveAsTable(metadata_table)
    logger.info(f"Recorded transformation log to {metadata_table}")
except Exception as e:
    logger.warning(f"Failed to record metadata (non-fatal): {e}")

print(f"✓ Silver transform completed: {target_full_name}")
