"""
Bronze Layer – Raw Ingestion
Reads source data via JDBC (credentials from AKV-backed secret scope) and
writes raw records as managed Delta tables in the Bronze Unity Catalog.

Secrets are read at runtime only; never logged or passed as plain parameters.
"""
import argparse
from datetime import datetime, timezone

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, lit


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--catalog", required=True)
    p.add_argument("--schema", required=True)
    p.add_argument("--secret-scope", required=True)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    # Read JDBC credentials from AKV-backed secret scope at runtime.
    # Keys must be pre-populated in Azure Key Vault before the job runs.
    scope = args.secret_scope
    jdbc_host = dbutils.secrets.get(scope, "jdbc-host")       # noqa: F821
    jdbc_db   = dbutils.secrets.get(scope, "jdbc-database")   # noqa: F821
    jdbc_user = dbutils.secrets.get(scope, "jdbc-user")       # noqa: F821
    jdbc_pass = dbutils.secrets.get(scope, "jdbc-password")   # noqa: F821

    jdbc_url = f"jdbc:sqlserver://{jdbc_host};databaseName={jdbc_db};encrypt=true;trustServerCertificate=false"

    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", "dbo.source_table")
        .option("user", jdbc_user)
        .option("password", jdbc_pass)
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        .load()
    )

    # Add ingestion audit column
    df = df.withColumn("_ingested_at", current_timestamp())

    target_table = f"`{args.catalog}`.`{args.schema}`.`source_raw`"
    df.write.format("delta").mode("append").saveAsTable(target_table)

    print(f"[bronze] Wrote {df.count()} rows to {target_table}")


if __name__ == "__main__":
    main()
