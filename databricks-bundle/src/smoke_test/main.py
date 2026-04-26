import argparse
import sys

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate medallion tables after orchestrator run.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", type=int, default=1)
    return parser.parse_args()


def row_count(spark: SparkSession, table_name: str) -> int:
    return spark.table(table_name).count()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    targets = [
        f"{args.bronze_catalog}.{args.bronze_schema}.raw_events",
        f"{args.silver_catalog}.{args.silver_schema}.events",
        f"{args.gold_catalog}.{args.gold_schema}.event_summary",
    ]

    failures = []
    for table in targets:
        try:
            count = row_count(spark, table)
            print(f"{table}: {count} rows")
            if count < args.min_row_count:
                failures.append(f"{table} has {count} rows (< {args.min_row_count})")
        except Exception as exc:
            failures.append(f"{table} failed query: {exc}")

    if failures:
        for failure in failures:
            print(f"FAILED: {failure}")
        sys.exit(1)

    print("Smoke test passed for Bronze/Silver/Gold tables.")


if __name__ == "__main__":
    main()
