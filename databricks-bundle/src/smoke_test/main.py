from __future__ import annotations

import argparse

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke-test medallion outputs.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", required=True, type=int)
    return parser.parse_args()


def assert_min_rows(spark: SparkSession, table_name: str, minimum: int) -> None:
    row_count = spark.table(table_name).count()
    if row_count < minimum:
        raise RuntimeError(f"Table {table_name} has {row_count} rows, below required minimum {minimum}.")


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    bronze_table = f"{args.bronze_catalog}.{args.bronze_schema}.events_bronze"
    silver_table = f"{args.silver_catalog}.{args.silver_schema}.events_silver"
    gold_table = f"{args.gold_catalog}.{args.gold_schema}.device_hourly_gold"

    assert_min_rows(spark, bronze_table, args.min_row_count)
    assert_min_rows(spark, silver_table, args.min_row_count)
    assert_min_rows(spark, gold_table, args.min_row_count)


if __name__ == "__main__":
    main()
