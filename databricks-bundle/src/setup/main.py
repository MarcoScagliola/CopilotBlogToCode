from __future__ import annotations

import argparse


def _create_schema_if_missing(catalog: str, schema_name: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema_name}`")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bootstrap Unity Catalog objects for medallion layers.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--bronze-storage-account", required=False)
    parser.add_argument("--silver-storage-account", required=False)
    parser.add_argument("--gold-storage-account", required=False)
    parser.add_argument("--bronze-access-connector-id", required=False)
    parser.add_argument("--silver-access-connector-id", required=False)
    parser.add_argument("--gold-access-connector-id", required=False)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    _create_schema_if_missing(args.bronze_catalog, args.bronze_schema)
    _create_schema_if_missing(args.silver_catalog, args.silver_schema)
    _create_schema_if_missing(args.gold_catalog, args.gold_schema)


if __name__ == "__main__":
    main()
