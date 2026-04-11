"""
Gold aggregation entrypoint.

Reads cleansed managed tables from the Silver catalog, applies business
aggregations, and writes serving-ready managed Delta tables to the Gold catalog.
Secrets are read at runtime from the AKV-backed secret scope — never logged.

Blog reference:
  Secure Medallion Architecture Pattern on Azure Databricks (Part I)
  https://techcommunity.microsoft.com/blog/analyticsonazure/...

Responsibility: Gold layer only.
  Run-as: gold service principal (read silver, write gold — least-privilege).
  Read source:  <source_catalog>.clean.<TODO_SILVER_SOURCE_TABLE>
  Write target: <target_catalog>.serving.<TODO_GOLD_TARGET_TABLE>
"""

from __future__ import annotations

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def main(secret_scope: str, source_catalog: str, target_catalog: str, env: str) -> None:
    spark = SparkSession.builder.getOrCreate()

    # ── Read from Silver (read-only grant for gold SP) ───────────────────────
    # TODO: update table name to match what Silver writes
    silver_df = spark.table(f"{source_catalog}.clean.<TODO_SILVER_SOURCE_TABLE>")

    # ── Business aggregation ─────────────────────────────────────────────────
    # TODO: replace with domain-specific aggregation / metric logic
    gold_df = (
        silver_df
        .groupBy("<TODO_DIMENSION_COLUMN>")
        .agg(
            F.count("*").alias("record_count"),
            # F.sum("<TODO_METRIC_COLUMN>").alias("total_value"),
        )
    )

    # ── Write as managed Delta table in Gold catalog ─────────────────────────
    spark.sql(f"USE CATALOG {target_catalog}")
    spark.sql("USE SCHEMA serving")

    (
        gold_df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"{target_catalog}.serving.<TODO_GOLD_TARGET_TABLE>")
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Gold aggregation job")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed secret scope name")
    parser.add_argument("--source-catalog", required=True, help="Silver Unity Catalog name")
    parser.add_argument("--target-catalog", required=True, help="Gold Unity Catalog name")
    parser.add_argument("--env", required=True, help="Deployment environment label")
    args = parser.parse_args()

    main(args.secret_scope, args.source_catalog, args.target_catalog, args.env)
