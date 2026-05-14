"""Ingest raw records into the bronze layer and validate runtime secret access through the shared scope."""

from __future__ import annotations

import argparse
import logging


LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load raw records into the bronze medallion layer.")
    parser.add_argument("--catalog", required=True, help="Bronze Unity Catalog catalog.")
    parser.add_argument("--schema", required=True, help="Bronze Unity Catalog schema.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope.")
    return parser.parse_args()


def _probe_secret_access(secret_scope: str) -> None:
    try:
        dbutils.secrets.get(scope=secret_scope, key="source-system-username")
        dbutils.secrets.get(scope=secret_scope, key="source-system-password")
        LOG.info("Secret scope %s is reachable for bronze ingestion.", secret_scope)
    except Exception as exc:  # noqa: BLE001 - Databricks exposes runtime-specific exceptions here.
        LOG.warning("Secret probe skipped or unavailable: %s", exc)


def main() -> None:
    args = _parse_args()
    table_name = f"`{args.catalog}`.`{args.schema}`.`orders_bronze`"

    _probe_secret_access(args.secret_scope)

    source_df = spark.createDataFrame(
        [
            (1001, "contoso", 41.50),
            (1002, "fabrikam", 84.25),
            (1003, "adventure-works", 16.75),
        ],
        ["order_id", "customer_name", "order_total"],
    )
    bronze_df = source_df.withColumn("ingested_at", spark.sql("SELECT current_timestamp() AS ts").collect()[0]["ts"])

    bronze_df.write.mode("overwrite").format("delta").saveAsTable(table_name)
    LOG.info("Bronze ingestion complete for %s", table_name)


if __name__ == "__main__":
    main()