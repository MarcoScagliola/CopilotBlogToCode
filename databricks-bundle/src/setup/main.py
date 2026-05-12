"""
setup/main.py — Unity Catalog setup entrypoint.

Creates the per-layer catalogs, schemas, and storage credentials in Unity Catalog.
Runs as the deployment service principal via the orchestrator job.
Called by the setup task in the orchestrator job before layer jobs execute.

All catalog/schema names and storage references come from job task parameters —
never hardcoded here. See SPEC.md § Databricks / Unity Catalog for names.
"""

import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Unity Catalog setup: create catalogs, schemas, and storage credentials."
    )

    # Bronze layer
    parser.add_argument("--bronze-catalog", required=True, help="Bronze Unity Catalog catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze Unity Catalog schema name.")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze ADLS Gen2 storage account name.")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze Access Connector resource ID.")

    # Silver layer
    parser.add_argument("--silver-catalog", required=True, help="Silver Unity Catalog catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Silver Unity Catalog schema name.")
    parser.add_argument("--silver-storage-account", required=True, help="Silver ADLS Gen2 storage account name.")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver Access Connector resource ID.")

    # Gold layer
    parser.add_argument("--gold-catalog", required=True, help="Gold Unity Catalog catalog name.")
    parser.add_argument("--gold-schema", required=True, help="Gold Unity Catalog schema name.")
    parser.add_argument("--gold-storage-account", required=True, help="Gold ADLS Gen2 storage account name.")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold Access Connector resource ID.")

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    layer_config = {
        "bronze": {
            "catalog": args.bronze_catalog,
            "schema": args.bronze_schema,
            "storage_account": args.bronze_storage_account,
            "access_connector_id": args.bronze_access_connector_id,
        },
        "silver": {
            "catalog": args.silver_catalog,
            "schema": args.silver_schema,
            "storage_account": args.silver_storage_account,
            "access_connector_id": args.silver_access_connector_id,
        },
        "gold": {
            "catalog": args.gold_catalog,
            "schema": args.gold_schema,
            "storage_account": args.gold_storage_account,
            "access_connector_id": args.gold_access_connector_id,
        },
    }

    print("Unity Catalog setup — resolved configuration:")
    for layer, cfg in layer_config.items():
        print(f"  {layer}:")
        for key, value in cfg.items():
            print(f"    {key}: {value}")

    # TODO: Implement Unity Catalog setup:
    #   1. Create storage credential per layer using the access connector resource ID.
    #   2. Create external location per layer pointing at the storage account container.
    #   3. Create catalog per layer bound to the external location.
    #   4. Create schema inside each catalog.
    #   5. Grant USE CATALOG and USE SCHEMA to the layer service principal.
    # See SPEC.md § Security and identity for the privilege model.
    print("TODO: Unity Catalog setup logic not yet implemented.")


if __name__ == "__main__":
    sys.exit(main())
