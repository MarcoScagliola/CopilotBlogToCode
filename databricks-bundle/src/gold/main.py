"""
gold/main.py — Gold layer aggregation entrypoint.

Reads conformed records from the Silver catalog layer and produces
business-level aggregates in the Gold catalog layer. Runs as the Gold
service principal with read access to Silver and write access to Gold only.
Reads runtime credentials from the Key Vault-backed secret scope.

All catalog/schema names and the secret scope name come from job task parameters
— never hardcoded here. See SPEC.md § Data model and § Security and identity.
"""

import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Gold aggregate: read from Silver, write business aggregates to Gold."
    )
    # Silver source
    parser.add_argument("--silver-catalog", required=True, help="Unity Catalog catalog name for Silver (source).")
    parser.add_argument("--silver-schema", required=True, help="Unity Catalog schema name for Silver (source).")
    # Gold target
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Gold (target).")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Gold (target).")
    parser.add_argument("--storage-account", required=True, help="Gold ADLS Gen2 storage account name.")
    parser.add_argument("--secret-scope", required=True, help="Key Vault-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    print("Gold aggregate — resolved configuration:")
    print(f"  silver_catalog:  {args.silver_catalog}")
    print(f"  silver_schema:   {args.silver_schema}")
    print(f"  catalog:         {args.catalog}")
    print(f"  schema:          {args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope:    {args.secret_scope}")

    # TODO: Implement Gold aggregation logic:
    #   1. Read conformed managed tables from {silver_catalog}.{silver_schema}.
    #   2. Apply business-level aggregations, joins, and enrichment.
    #   3. Write aggregated records as managed tables in {catalog}.{schema}.
    # See SPEC.md § Data model for specific source/target tables (not stated in article).
    print("TODO: Gold aggregation logic not yet implemented.")


if __name__ == "__main__":
    sys.exit(main())
