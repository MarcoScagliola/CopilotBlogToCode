"""
silver/main.py — Silver layer transformation entrypoint.

Reads curated data from the Bronze catalog layer and writes validated,
conformed records to the Silver catalog layer. Runs as the Silver service
principal with read access to Bronze and write access to Silver only.
Reads runtime credentials from the Key Vault-backed secret scope.

All catalog/schema names and the secret scope name come from job task parameters
— never hardcoded here. See SPEC.md § Data model and § Security and identity.
"""

import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Silver transform: read from Bronze, write curated records to Silver."
    )
    # Bronze source
    parser.add_argument("--bronze-catalog", required=True, help="Unity Catalog catalog name for Bronze (source).")
    parser.add_argument("--bronze-schema", required=True, help="Unity Catalog schema name for Bronze (source).")
    # Silver target
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Silver (target).")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Silver (target).")
    parser.add_argument("--storage-account", required=True, help="Silver ADLS Gen2 storage account name.")
    parser.add_argument("--secret-scope", required=True, help="Key Vault-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    print("Silver transform — resolved configuration:")
    print(f"  bronze_catalog:  {args.bronze_catalog}")
    print(f"  bronze_schema:   {args.bronze_schema}")
    print(f"  catalog:         {args.catalog}")
    print(f"  schema:          {args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope:    {args.secret_scope}")

    # TODO: Implement Silver transformation logic:
    #   1. Read raw managed tables from {bronze_catalog}.{bronze_schema}.
    #   2. Apply cleaning, deduplication, and conformance transformations.
    #   3. Write validated records as managed tables in {catalog}.{schema}.
    #   4. Enforce data quality expectations if required (see SPEC.md § Data model).
    # See SPEC.md § Data model for specific source/target tables (not stated in article).
    print("TODO: Silver transformation logic not yet implemented.")


if __name__ == "__main__":
    sys.exit(main())
