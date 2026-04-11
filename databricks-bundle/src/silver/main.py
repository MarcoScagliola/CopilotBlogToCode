"""
Silver transformation entrypoint.

Reads raw managed tables from the Bronze catalog, applies data quality checks
and enrichment, and writes cleansed managed Delta tables to the Silver catalog.
Secrets are read at runtime from the AKV-backed secret scope — never logged.

Blog reference:
  Secure Medallion Architecture Pattern on Azure Databricks (Part I)
  https://techcommunity.microsoft.com/blog/analyticsonazure/...

Responsibility: Silver layer only.
  Run-as: silver service principal (read bronze, write silver — least-privilege).
  Read source:  <source_catalog>.raw.<TODO_BRONZE_SOURCE_TABLE>
  Write target: <target_catalog>.clean.<TODO_SILVER_TARGET_TABLE>
"""

from __future__ import annotations

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def main(secret_scope: str, source_catalog: str, target_catalog: str, env: str) -> None:
    spark = SparkSession.builder.getOrCreate()

    # ── Read from Bronze (read-only grant for silver SP) ────────────────────
    # TODO: update table name to match what Bronze writes
    bronze_df = spark.table(f"{source_catalog}.raw.<TODO_BRONZE_SOURCE_TABLE>")

    # ── Data quality and transformation ─────────────────────────────────────
    # TODO: replace with domain-specific cleansing and enrichment logic
    silver_df = (
        bronze_df
        .dropDuplicates()
        .filter(F.col("<TODO_NON_NULL_COLUMN>").isNotNull())
        # example: standardise a timestamp column
        # .withColumn("event_ts", F.to_timestamp("raw_timestamp_col"))
    )

    # ── Write as managed Delta table in Silver catalog ───────────────────────
    spark.sql(f"USE CATALOG {target_catalog}")
    spark.sql("USE SCHEMA clean")

    (
        silver_df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"{target_catalog}.clean.<TODO_SILVER_TARGET_TABLE>")
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Silver transformation job")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed secret scope name")
    parser.add_argument("--source-catalog", required=True, help="Bronze Unity Catalog name")
    parser.add_argument("--target-catalog", required=True, help="Silver Unity Catalog name")
    parser.add_argument("--env", required=True, help="Deployment environment label")
    args = parser.parse_args()

    main(args.secret_scope, args.source_catalog, args.target_catalog, args.env)
