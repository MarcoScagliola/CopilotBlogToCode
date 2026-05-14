from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description="Smoke test for medallion layer outputs.")
  parser.add_argument("--bronze-catalog", required=True)
  parser.add_argument("--bronze-schema", required=True)
  parser.add_argument("--silver-catalog", required=True)
  parser.add_argument("--silver-schema", required=True)
  parser.add_argument("--gold-catalog", required=True)
  parser.add_argument("--gold-schema", required=True)
  parser.add_argument("--min-row-count", type=int, default=1)
  return parser.parse_args()


def assert_table_has_rows(table_name: str, min_rows: int) -> None:
  row_count = spark.sql(f"SELECT COUNT(*) AS c FROM {table_name}").collect()[0]["c"]
  if row_count < min_rows:
    raise RuntimeError(f"Smoke test failed for {table_name}: expected >= {min_rows}, got {row_count}")


def main() -> None:
  args = parse_args()

  bronze_table = f"{args.bronze_catalog}.{args.bronze_schema}.orders_bronze"
  silver_table = f"{args.silver_catalog}.{args.silver_schema}.orders_silver"
  gold_table = f"{args.gold_catalog}.{args.gold_schema}.orders_gold_metrics"

  assert_table_has_rows(bronze_table, args.min_row_count)
  assert_table_has_rows(silver_table, args.min_row_count)
  assert_table_has_rows(gold_table, 1)

  print("Smoke test completed successfully.")


if __name__ == "__main__":
  main()