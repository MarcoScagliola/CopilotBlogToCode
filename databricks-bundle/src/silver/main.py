"""
Silver layer entrypoint — silver-layer job.

Reads cleansed data from the Bronze catalog/schema, applies transformations,
and writes to the Silver catalog/schema using managed tables in Unity Catalog.
Credentials are read at runtime from the AKV-backed secret scope.

TODO: Implement transformation logic once Bronze table names and Silver target
      tables are confirmed. See SPEC.md § Data model and TODO.md § Post-infrastructure.
"""

from __future__ import annotations

import argparse
import sys


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Silver layer: transform Bronze data into Silver."
    )
    # Source (Bronze)
    parser.add_argument("--bronze-catalog", required=True, help="Unity Catalog catalog name for Bronze (source).")
    parser.add_argument("--bronze-schema", required=True, help="Unity Catalog schema name for Bronze (source).")
    # Target (Silver)
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Silver (target).")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Silver (target).")
    parser.add_argument("--storage-account", required=True, help="Storage account name for Silver.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    print("=== Silver Layer Configuration ===")
    print(f"  source  catalog: {args.bronze_catalog}.{args.bronze_schema}")
    print(f"  target  catalog: {args.catalog}.{args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope   : {args.secret_scope}")

    # TODO: read source credentials via dbutils.secrets.get(args.secret_scope, "<key>")
    # TODO: implement transformation from bronze_catalog.bronze_schema into args.catalog.args.schema
    print("Silver transformation complete (stub).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
