"""Smoke test entrypoint for medallion tables."""

import argparse

from pyspark.sql import SparkSession


def _assert_table_rows(spark: SparkSession, table_name: str, minimum_rows: int) -> None:
    count = spark.table(table_name).count()
    if count < minimum_rows:
        raise RuntimeError(f"Table {table_name} has {count} rows; expected at least {minimum_rows}.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Smoke test for medallion outputs.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", required=True, type=int)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    _assert_table_rows(spark, f"{args.bronze_catalog}.{args.bronze_schema}.raw_events", args.min_row_count)
    _assert_table_rows(spark, f"{args.silver_catalog}.{args.silver_schema}.events", args.min_row_count)
    _assert_table_rows(spark, f"{args.gold_catalog}.{args.gold_schema}.event_summary", args.min_row_count)

    print("Smoke test passed.")


if __name__ == "__main__":
    main()