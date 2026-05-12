"""
setup/main.py — Medallion setup job entrypoint.

Registers Unity Catalog External Locations for each layer (Bronze, Silver,
Gold) backed by the corresponding Databricks Access Connector SAMI, and
creates the per-layer catalogs and schemas if they do not already exist.

This job runs once per environment as a pre-deploy step before any layer
Lakeflow jobs. It is idempotent: re-running against an already-provisioned
workspace is safe.

Arguments are injected by the Databricks job runner via spark_python_task
parameters. See databricks-bundle/resources/jobs.yml for the parameter list.
"""
from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Medallion setup: External Locations, catalogs, schemas.")
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


def main() -> None:
    args = parse_args()

    layers = {
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

    # TODO: implement using Databricks SDK or spark.sql() calls.
    # Resolution: for each layer:
    #   1. Create or update a Storage Credential referencing access_connector_id.
    #   2. Create or update an External Location for the layer pointing to
    #      the ADLS Gen2 container backed by storage_account.
    #   3. CREATE CATALOG IF NOT EXISTS <catalog>.
    #   4. CREATE SCHEMA IF NOT EXISTS <catalog>.<schema>.
    # All operations are idempotent (IF NOT EXISTS guards).

    for layer_name, cfg in layers.items():
        print(
            f"[setup] {layer_name}: catalog={cfg['catalog']}, schema={cfg['schema']}, "
            f"storage={cfg['storage_account']}, connector={cfg['access_connector_id']}"
        )


if __name__ == "__main__":
    main()
