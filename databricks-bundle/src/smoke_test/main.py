import argparse
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test: validate Medallion layers.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", type=int, default=1)
    return parser.parse_args()


def validate_table(spark: SparkSession, catalog: str, schema: str, table: str, min_rows: int) -> bool:
    full_table_name = f"{catalog}.{schema}.{table}"
    try:
        df = spark.table(full_table_name)
        row_count = df.count()
        status = "PASS" if row_count >= min_rows else "FAIL"
        print(f"[{status}] {full_table_name}: {row_count} rows (min expected: {min_rows})")
        return row_count >= min_rows
    except Exception as e:
        print(f"[FAIL] {full_table_name}: {str(e)}")
        return False


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    checks = [
        (args.bronze_catalog, args.bronze_schema, "raw_events"),
        (args.silver_catalog, args.silver_schema, "events"),
        (args.gold_catalog, args.gold_schema, "event_summary"),
    ]

    results = [validate_table(spark, cat, sch, tbl, args.min_row_count) for cat, sch, tbl in checks]

    if all(results):
        print("\nSmoke test: ALL CHECKS PASSED")
        return
    else:
        raise Exception("Smoke test: SOME CHECKS FAILED")


if __name__ == "__main__":
    main()
