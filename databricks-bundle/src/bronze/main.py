"""
Bronze ingestion entrypoint.

Reads from a source system and writes managed Delta tables to the Bronze catalog.
Secrets are read at runtime from the AKV-backed secret scope — never logged or printed.

Blog reference:
  Secure Medallion Architecture Pattern on Azure Databricks (Part I)
  https://techcommunity.microsoft.com/blog/analyticsonazure/...

Responsibility: Bronze layer only.
  Run-as: bronze service principal (least-privilege to bronze catalog).
  Write target: <bronze_catalog>.raw.<TODO_TARGET_TABLE>
"""

from __future__ import annotations

import argparse

from pyspark.sql import SparkSession


def main(secret_scope: str, catalog: str, env: str) -> None:
    spark = SparkSession.builder.getOrCreate()

    # ── Read source credentials at runtime — never log these values ─────────
    # TODO: replace key names with the actual AKV secret keys for your source
    source_url = dbutils.secrets.get(  # noqa: F821  (dbutils injected by Databricks)
        scope=secret_scope,
        key="<TODO_SOURCE_URL_SECRET_KEY>",
    )
    source_user = dbutils.secrets.get(
        scope=secret_scope,
        key="<TODO_SOURCE_USER_SECRET_KEY>",
    )
    source_password = dbutils.secrets.get(
        scope=secret_scope,
        key="<TODO_SOURCE_PASSWORD_SECRET_KEY>",
    )

    # ── Set catalog and schema context ──────────────────────────────────────
    spark.sql(f"USE CATALOG {catalog}")
    spark.sql("USE SCHEMA raw")

    # ── Ingest from source — TODO: adapt format/options for your source ─────
    df = (
        spark.read.format("jdbc")
        .option("url", source_url)
        .option("user", source_user)
        .option("password", source_password)
        .option("dbtable", "<TODO_SOURCE_TABLE>")
        .load()
    )

    # ── Write as managed Delta table in Bronze catalog ───────────────────────
    (
        df.write.format("delta")
        .mode("append")
        .option("mergeSchema", "true")
        .saveAsTable(f"{catalog}.raw.<TODO_TARGET_TABLE>")
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bronze ingestion job")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed secret scope name")
    parser.add_argument("--catalog", required=True, help="Unity Catalog name for Bronze layer")
    parser.add_argument("--env", required=True, help="Deployment environment label")
    args = parser.parse_args()

    main(args.secret_scope, args.catalog, args.env)
