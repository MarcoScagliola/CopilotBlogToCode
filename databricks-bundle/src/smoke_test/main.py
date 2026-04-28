import argparse
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate medallion outputs")
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
        raise RuntimeError(f"Table {table_name} has {row_count} rows, expected at least {minimum}")


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-smoke-test").getOrCreate()

    assert_min_rows(spark, f"{args.bronze_catalog}.{args.bronze_schema}.events_bronze", args.min_row_count)
    assert_min_rows(spark, f"{args.silver_catalog}.{args.silver_schema}.events_silver", args.min_row_count)
    assert_min_rows(spark, f"{args.gold_catalog}.{args.gold_schema}.event_type_daily_gold", args.min_row_count)

    spark.stop()


if __name__ == "__main__":
    main()
