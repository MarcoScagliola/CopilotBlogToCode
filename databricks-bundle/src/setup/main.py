"""Initialize layer namespaces and log the Unity Catalog isolation contract for the workspace."""

from __future__ import annotations

import argparse
import logging


LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare medallion namespaces and setup metadata.")
    parser.add_argument("--workspace-resource-id", required=True, help="Azure resource ID of the Databricks workspace.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze Unity Catalog catalog.")
    parser.add_argument("--silver-catalog", required=True, help="Silver Unity Catalog catalog.")
    parser.add_argument("--gold-catalog", required=True, help="Gold Unity Catalog catalog.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze Unity Catalog schema.")
    parser.add_argument("--silver-schema", required=True, help="Silver Unity Catalog schema.")
    parser.add_argument("--gold-schema", required=True, help="Gold Unity Catalog schema.")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze storage account name.")
    parser.add_argument("--silver-storage-account", required=True, help="Silver storage account name.")
    parser.add_argument("--gold-storage-account", required=True, help="Gold storage account name.")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze access connector resource ID.")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver access connector resource ID.")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold access connector resource ID.")
    parser.add_argument("--bronze-principal-client-id", required=True, help="Application (client) ID of the bronze Service Principal.")
    parser.add_argument("--silver-principal-client-id", required=True, help="Application (client) ID of the silver Service Principal.")
    parser.add_argument("--gold-principal-client-id", required=True, help="Application (client) ID of the gold Service Principal.")
    return parser.parse_args()


def _run_sql(statement: str) -> None:
    LOG.info("Executing SQL: %s", statement)
    spark.sql(statement)


def _ensure_namespace(catalog: str, schema_name: str) -> None:
    _run_sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
    _run_sql(f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema_name}`")


def _log_layer_contract(layer: str, storage_account: str, connector_id: str, principal_client_id: str) -> None:
    LOG.info(
        "%s layer contract: storage_account=%s access_connector_id=%s principal_client_id=%s",
        layer,
        storage_account,
        connector_id,
        principal_client_id,
    )


def main() -> None:
    args = _parse_args()

    _ensure_namespace(args.bronze_catalog, args.bronze_schema)
    _ensure_namespace(args.silver_catalog, args.silver_schema)
    _ensure_namespace(args.gold_catalog, args.gold_schema)

    _log_layer_contract("bronze", args.bronze_storage_account, args.bronze_access_connector_id, args.bronze_principal_client_id)
    _log_layer_contract("silver", args.silver_storage_account, args.silver_access_connector_id, args.silver_principal_client_id)
    _log_layer_contract("gold", args.gold_storage_account, args.gold_access_connector_id, args.gold_principal_client_id)

    LOG.info("Workspace resource context: %s", args.workspace_resource_id)
    LOG.info("Setup complete for bronze, silver, and gold namespaces.")


if __name__ == "__main__":
    main()