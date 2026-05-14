from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description="Initialize medallion catalogs and schemas.")
  parser.add_argument("--bronze-catalog", required=True)
  parser.add_argument("--silver-catalog", required=True)
  parser.add_argument("--gold-catalog", required=True)
  parser.add_argument("--bronze-schema", required=True)
  parser.add_argument("--silver-schema", required=True)
  parser.add_argument("--gold-schema", required=True)
  parser.add_argument("--bronze-storage-account", required=True)
  parser.add_argument("--silver-storage-account", required=True)
  parser.add_argument("--gold-storage-account", required=True)
  parser.add_argument("--bronze-access-connector-id", required=True)
  parser.add_argument("--silver-access-connector-id", required=True)
  parser.add_argument("--gold-access-connector-id", required=True)
  return parser.parse_args()


def ensure_namespace(catalog: str, schema: str) -> None:
  spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog}")
  spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")


def main() -> None:
  args = parse_args()

  ensure_namespace(args.bronze_catalog, args.bronze_schema)
  ensure_namespace(args.silver_catalog, args.silver_schema)
  ensure_namespace(args.gold_catalog, args.gold_schema)

  print("Setup completed for bronze, silver, and gold namespaces.")


if __name__ == "__main__":
  main()