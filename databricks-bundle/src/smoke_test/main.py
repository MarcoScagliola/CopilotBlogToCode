"""Validate medallion layer tables exist and contain data."""

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
  parser = argparse.ArgumentParser(description="Smoke test for medallion tables")
  parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog")
  parser.add_argument("--bronze-schema", required=True, help="Bronze schema")
  parser.add_argument("--silver-catalog", required=True, help="Silver catalog")
  parser.add_argument("--silver-schema", required=True, help="Silver schema")
  parser.add_argument("--gold-catalog", required=True, help="Gold catalog")
  parser.add_argument("--gold-schema", required=True, help="Gold schema")
  parser.add_argument("--min-row-count", required=True, type=int, help="Minimum rows expected")
  args = parser.parse_args()

  spark = SparkSession.builder.getOrCreate()
  bronze_table = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`raw_events`"
  silver_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`refined_events`"
  gold_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.`curated_metrics`"

  _assert_min_rows(spark, bronze_table, args.min_row_count)
  _assert_min_rows(spark, silver_table, args.min_row_count)
  _assert_min_rows(spark, gold_table, 1)

  log.info("Smoke test passed for bronze, silver, and gold tables")


if __name__ == "__main__":
  main()