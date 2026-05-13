"""Run a lightweight end-to-end table presence and row-count check."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _assert_rows(spark: SparkSession, table_name: str, min_rows: int) -> None:
    count = spark.table(table_name).count()
    if count < min_rows:
        raise ValueError(f"Table {table_name} has {count} rows, expected at least {min_rows}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate medallion tables exist and contain rows")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", required=True, type=int)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    _assert_rows(spark, f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`transactions_bronze`", args.min_row_count)
    _assert_rows(spark, f"`{args.silver_catalog}`.`{args.silver_schema}`.`transactions_silver`", args.min_row_count)
    _assert_rows(spark, f"`{args.gold_catalog}`.`{args.gold_schema}`.`transactions_gold`", args.min_row_count)

    log.info("Smoke test passed for bronze/silver/gold tables")


if __name__ == "__main__":
    main()
