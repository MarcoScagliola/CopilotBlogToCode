"""
Setup entrypoint — medallion-setup job.

Provisions or validates Unity Catalog objects and external locations for all
three medallion layers. Receives layer coordinates as CLI arguments supplied
by the Databricks bundle at task execution time.

TODO: Implement Unity Catalog setup logic (create catalogs, schemas, external
      locations, and storage credentials) once source-system details and catalog
      names are confirmed. See SPEC.md § Data model and TODO.md § Post-infrastructure.
"""

from __future__ import annotations

import argparse
import sys


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Medallion setup: provision Unity Catalog objects for all layers."
    )

    # Bronze layer coordinates
    parser.add_argument("--bronze-catalog", required=True, help="Unity Catalog catalog name for Bronze.")
    parser.add_argument("--bronze-schema", required=True, help="Unity Catalog schema name for Bronze.")
    parser.add_argument("--bronze-storage-account", required=True, help="Storage account name for Bronze.")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Azure resource ID of the Bronze Access Connector.")

    # Silver layer coordinates
    parser.add_argument("--silver-catalog", required=True, help="Unity Catalog catalog name for Silver.")
    parser.add_argument("--silver-schema", required=True, help="Unity Catalog schema name for Silver.")
    parser.add_argument("--silver-storage-account", required=True, help="Storage account name for Silver.")
    parser.add_argument("--silver-access-connector-id", required=True, help="Azure resource ID of the Silver Access Connector.")

    # Gold layer coordinates
    parser.add_argument("--gold-catalog", required=True, help="Unity Catalog catalog name for Gold.")
    parser.add_argument("--gold-schema", required=True, help="Unity Catalog schema name for Gold.")
    parser.add_argument("--gold-storage-account", required=True, help="Storage account name for Gold.")
    parser.add_argument("--gold-access-connector-id", required=True, help="Azure resource ID of the Gold Access Connector.")

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    print("=== Medallion Setup Configuration ===")
    for layer in ("bronze", "silver", "gold"):
        print(f"  [{layer}]")
        print(f"    catalog           : {getattr(args, f'{layer}_catalog')}")
        print(f"    schema            : {getattr(args, f'{layer}_schema')}")
        print(f"    storage_account   : {getattr(args, f'{layer}_storage_account')}")
        print(f"    access_connector  : {getattr(args, f'{layer}_access_connector_id')}")

    # TODO: implement UC catalog / schema / external-location / storage-credential provisioning
    print("Setup complete (stub — no UC objects provisioned).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
