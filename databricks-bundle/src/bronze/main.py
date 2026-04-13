# Databricks notebook source
"""
Bronze Layer: JDBC Ingestion
Ingest raw data from external database to Bronze UC table.
"""

import jaydebeapi
import pandas as pd
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# PARAMETERS (injected by DAB job)
# ============================================================================

dbutils.widgets.text("catalog", "blg_bronze", "Target Catalog")
dbutils.widgets.text("schema", "raw_data", "Target Schema")
dbutils.widgets.text("source_table", "source_table", "Source Table Name (JDBC)")
dbutils.widgets.text("secret_scope", "blg-dev-uks-akv", "Secret Scope Name")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
source_table = dbutils.widgets.get("source_table")
secret_scope = dbutils.widgets.get("secret_scope")

logger.info(f"Starting Bronze ingest: {catalog}.{schema} from {source_table}")

# ============================================================================
# RETRIEVE JDBC CREDENTIALS FROM SECRET SCOPE
# ============================================================================

try:
    jdbc_host = dbutils.secrets.get(scope=secret_scope, key="jdbc-host")
    jdbc_database = dbutils.secrets.get(scope=secret_scope, key="jdbc-database")
    jdbc_user = dbutils.secrets.get(scope=secret_scope, key="jdbc-user")
    jdbc_password = dbutils.secrets.get(scope=secret_scope, key="jdbc-password")
    logger.info(f"Retrieved JDBC credentials from secret scope: {secret_scope}")
except Exception as e:
    logger.error(f"Failed to retrieve JDBC credentials: {e}")
    raise

# ============================================================================
# JDBC CONNECTION & READ
# ============================================================================

# Build connection string (example: SQL Server)
# Adjust driver and port for your source database type
connection_string = f"jdbc:sqlserver://{jdbc_host};databaseName={jdbc_database};user={jdbc_user};password={jdbc_password}"

try:
    # PySpark SQL read from JDBC
    bronze_df = spark.read \
        .format("jdbc") \
        .option("url", connection_string) \
        .option("dbtable", source_table) \
        .option("user", jdbc_user) \
        .option("password", jdbc_password) \
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
        .option("fetchsize", "10000") \
        .load()
    
    logger.info(f"Read {bronze_df.count()} rows from {source_table}")
    print(f"Schema:\n{bronze_df.printSchema()}")
    
except Exception as e:
    logger.error(f"Failed to read from JDBC source: {e}")
    raise

# ============================================================================
# WRITE TO BRONZE MANAGED TABLE
# ============================================================================

table_name = f"{catalog}.{schema}.{source_table.lower()}"

try:
    # Write as managed table with MERGE semantics (upsert on source_id if present)
    bronze_df \
        .write \
        .format("delta") \
        .mode("overwrite") \
        .option("mergeSchema", "true") \
        .saveAsTable(table_name)
    
    logger.info(f"Successfully wrote {bronze_df.count()} rows to {table_name}")
    
except Exception as e:
    logger.error(f"Failed to write to Bronze table: {e}")
    raise

# ============================================================================
# RECORD INGESTION METADATA
# ============================================================================

metadata_df = spark.createDataFrame(
    [
        {
            "log_date": datetime.utcnow().isoformat(),
            "layer": "bronze",
            "source_table": source_table,
            "target_table": table_name,
            "row_count": bronze_df.count(),
            "status": "SUCCESS"
        }
    ]
)

metadata_table = f"{catalog}.{schema}._ingest_log"
try:
    metadata_df \
        .write \
        .format("delta") \
        .mode("append") \
        .option("mergeSchema", "true") \
        .option("path", f"/mnt/medallion/{schema}/_ingest_log") \
        .saveAsTable(metadata_table)
    logger.info(f"Recorded ingestion log to {metadata_table}")
except Exception as e:
    logger.warning(f"Failed to record metadata (non-fatal): {e}")

print(f"✓ Bronze ingest completed: {table_name}")
