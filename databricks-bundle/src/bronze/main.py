"""
bronze/main.py — Bronze layer ingestion entrypoint.

Ingests raw data from source systems into the Bronze Unity Catalog layer.
Runs as the Bronze service principal with least-privilege access to Bronze
storage only. Reads runtime credentials from the Key Vault-backed secret scope.

All catalog/schema names and the secret scope name come from job task parameters
— never hardcoded here. See SPEC.md § Data model and § Security and identity.
"""

import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Bronze ingestion: ingest raw data into the Bronze catalog layer."
    )
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Bronze.")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Bronze.")
    parser.add_argument("--storage-account", required=True, help="Bronze ADLS Gen2 storage account name.")
    parser.add_argument("--secret-scope", required=True, help="Key Vault-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    print("Bronze ingestion — resolved configuration:")
    print(f"  catalog:         {args.catalog}")
    print(f"  schema:          {args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope:    {args.secret_scope}")

    # TODO: Implement Bronze ingestion logic:
    #   1. Read source credentials at runtime via dbutils.secrets.get(scope, key).
    #      Never print or log secret values.
    #   2. Connect to source system(s) — see SPEC.md § Data model / Source systems.
    #   3. Ingest raw data as managed tables in {catalog}.{schema}.
    #   4. Apply schema enforcement and basic data quality checks if required.
    # See SPEC.md § Data model for specific source systems (not stated in article).
    print("TODO: Bronze ingestion logic not yet implemented.")


if __name__ == "__main__":
    sys.exit(main())
