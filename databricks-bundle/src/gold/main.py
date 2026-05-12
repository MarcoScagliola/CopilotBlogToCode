"""
Gold layer entrypoint — gold-layer job.

Reads enriched data from the Silver catalog/schema, applies aggregations and
business logic, and writes to the Gold catalog/schema using managed tables in
Unity Catalog. Credentials are read at runtime from the AKV-backed secret scope.

TODO: Implement aggregation logic once Silver table names and Gold target tables
      are confirmed. See SPEC.md § Data model and TODO.md § Post-infrastructure.
"""

from __future__ import annotations

import argparse
import sys


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gold layer: aggregate Silver data into Gold serving layer."
    )
    # Source (Silver)
    parser.add_argument("--silver-catalog", required=True, help="Unity Catalog catalog name for Silver (source).")
    parser.add_argument("--silver-schema", required=True, help="Unity Catalog schema name for Silver (source).")
    # Target (Gold)
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Gold (target).")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Gold (target).")
    parser.add_argument("--storage-account", required=True, help="Storage account name for Gold.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    print("=== Gold Layer Configuration ===")
    print(f"  source  catalog: {args.silver_catalog}.{args.silver_schema}")
    print(f"  target  catalog: {args.catalog}.{args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope   : {args.secret_scope}")

    # TODO: read source credentials via dbutils.secrets.get(args.secret_scope, "<key>")
    # TODO: implement aggregation from silver_catalog.silver_schema into args.catalog.args.schema
    print("Gold aggregation complete (stub).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
