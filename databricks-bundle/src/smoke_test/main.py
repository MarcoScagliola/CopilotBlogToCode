"""Validate that the Bronze, Silver, and Gold tables exist and contain data."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _assert_row_count(spark: SparkSession, table_name: str, min_row_count: int) -> None:
    row_count = spark.table(table_name).count()
    if row_count < min_row_count:
        raise RuntimeError(f"Table {table_name} has {row_count} rows, expected at least {min_row_count}")
    log.info("Validated %s with %s rows", table_name, row_count)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run a smoke test across Bronze, Silver, and Gold tables.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog")
    parser.add_argument("--silver-schema", required=True, help="Silver schema")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog")
    parser.add_argument("--gold-schema", required=True, help="Gold schema")
    parser.add_argument("--min-row-count", required=True, type=int, help="Minimum row count expected per table")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    _assert_row_count(spark, f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`raw_events`", args.min_row_count)
    _assert_row_count(spark, f"`{args.silver_catalog}`.`{args.silver_schema}`.`events`", args.min_row_count)
    _assert_row_count(spark, f"`{args.gold_catalog}`.`{args.gold_schema}`.`event_summary`", args.min_row_count)
    log.info("Smoke test completed successfully")


if __name__ == "__main__":
    main()
