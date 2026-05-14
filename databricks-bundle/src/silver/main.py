from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description="Silver layer transformer.")
  parser.add_argument("--source-catalog", required=True)
  parser.add_argument("--source-schema", required=True)
  parser.add_argument("--target-catalog", required=True)
  parser.add_argument("--target-schema", required=True)
  return parser.parse_args()


def main() -> None:
  args = parse_args()
  source_table = f"{args.source_catalog}.{args.source_schema}.orders_bronze"
  target_table = f"{args.target_catalog}.{args.target_schema}.orders_silver"

  spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {target_table}
    USING DELTA
    AS
    SELECT
      order_id,
      CAST(ingested_at AS TIMESTAMP) AS processed_at
    FROM {source_table}
    """
  )

  print(f"Silver transform completed for {target_table}")


if __name__ == "__main__":
  main()