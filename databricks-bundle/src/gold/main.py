from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description="Gold layer aggregation.")
  parser.add_argument("--source-catalog", required=True)
  parser.add_argument("--source-schema", required=True)
  parser.add_argument("--target-catalog", required=True)
  parser.add_argument("--target-schema", required=True)
  return parser.parse_args()


def main() -> None:
  args = parse_args()
  source_table = f"{args.source_catalog}.{args.source_schema}.orders_silver"
  target_table = f"{args.target_catalog}.{args.target_schema}.orders_gold_metrics"

  spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {target_table}
    USING DELTA
    AS
    SELECT
      DATE(processed_at) AS processing_date,
      COUNT(*) AS order_count
    FROM {source_table}
    GROUP BY DATE(processed_at)
    """
  )

  print(f"Gold aggregation completed for {target_table}")


if __name__ == "__main__":
  main()