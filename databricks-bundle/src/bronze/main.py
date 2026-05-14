"""Seed the bronze layer with synthetic ingestion records for the medallion pipeline."""

import argparse
import logging
from datetime import datetime, timezone

from pyspark.sql import SparkSession

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

TABLE_NAME = "bronze_layer_runs"


def _qualified_table(catalog: str, schema: str) -> str:
    return f"`{catalog}`.`{schema}`.`{TABLE_NAME}`"


def main() -> None:
    parser = argparse.ArgumentParser(description="Write a synthetic bronze layer table.")
    parser.add_argument("--catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--schema", required=True, help="Bronze schema name.")
    parser.add_argument("--secret-scope", required=True, help="Azure Key Vault-backed secret scope name.")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    target_table = _qualified_table(args.catalog, args.schema)
    now = datetime.now(timezone.utc).isoformat()

    log.info("Writing bronze seed table %s using secret scope %s", target_table, args.secret_scope)
    rows = [
        {
            "layer": "bronze",
            "catalog": args.catalog,
            "schema": args.schema,
            "secret_scope": args.secret_scope,
            "ingested_at": now,
        }
    ]

    spark.createDataFrame(rows).write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)
    log.info("Bronze write complete")


if __name__ == "__main__":
    main()