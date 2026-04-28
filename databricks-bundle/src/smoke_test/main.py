"""Validate that Bronze, Silver, and Gold outputs contain data."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _assert_min_rows(spark: SparkSession, table_name: str, minimum: int) -> None:
    count = spark.table(table_name).count()
    if count < minimum:
        raise RuntimeError(f"Table {table_name} has {count} rows, expected at least {minimum}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Medallion smoke tests")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name")
    parser.add_argument("--min-row-count", required=True, type=int, help="Minimum rows expected in each output table")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("secure-medallion-smoke-test").getOrCreate()
    _assert_min_rows(spark, f"{args.bronze_catalog}.{args.bronze_schema}.events_bronze", args.min_row_count)
    _assert_min_rows(spark, f"{args.silver_catalog}.{args.silver_schema}.events_silver", args.min_row_count)
    _assert_min_rows(spark, f"{args.gold_catalog}.{args.gold_schema}.event_type_daily_gold", args.min_row_count)
    spark.stop()
    log.info("Smoke test complete")


if __name__ == "__main__":
    main()
