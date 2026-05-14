from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description="Bronze layer loader.")
  parser.add_argument("--catalog", required=True)
  parser.add_argument("--schema", required=True)
  parser.add_argument("--secret-scope", required=True)
  return parser.parse_args()


def main() -> None:
  args = parse_args()
  table_name = f"{args.catalog}.{args.schema}.orders_bronze"

  df = spark.range(1, 101).withColumnRenamed("id", "order_id")
  df.createOrReplaceTempView("source_orders")

  spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {table_name}
    USING DELTA
    AS SELECT order_id, current_timestamp() AS ingested_at FROM source_orders
    """
  )

  print(f"Bronze load completed for {table_name}")


if __name__ == "__main__":
  main()