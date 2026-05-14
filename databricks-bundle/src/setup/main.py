"""Prepare Unity Catalog containers for the medallion layers and log the workspace wiring."""

import argparse
import logging

from pyspark.sql import SparkSession

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)


def _qualified_catalog_schema(catalog: str, schema: str) -> str:
    return f"`{catalog}`.`{schema}`"


def _create_catalog_and_schema(spark: SparkSession, catalog: str, schema: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {_qualified_catalog_schema(catalog, schema)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Create medallion catalogs and schemas.")
    parser.add_argument("--workspace-resource-id", required=True, help="Azure Databricks workspace resource ID.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name.")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name.")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name.")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze storage account name.")
    parser.add_argument("--silver-storage-account", required=True, help="Silver storage account name.")
    parser.add_argument("--gold-storage-account", required=True, help="Gold storage account name.")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze access connector ID.")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver access connector ID.")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold access connector ID.")
    parser.add_argument("--bronze-principal-client-id", required=True, help="Bronze service principal client ID.")
    parser.add_argument("--silver-principal-client-id", required=True, help="Silver service principal client ID.")
    parser.add_argument("--gold-principal-client-id", required=True, help="Gold service principal client ID.")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    log.info("workspace_resource_id=%s", args.workspace_resource_id)
    layers = [
        ("bronze", args.bronze_catalog, args.bronze_schema, args.bronze_storage_account, args.bronze_access_connector_id, args.bronze_principal_client_id),
        ("silver", args.silver_catalog, args.silver_schema, args.silver_storage_account, args.silver_access_connector_id, args.silver_principal_client_id),
        ("gold", args.gold_catalog, args.gold_schema, args.gold_storage_account, args.gold_access_connector_id, args.gold_principal_client_id),
    ]

    for layer_name, catalog, schema, storage_account, access_connector_id, principal_client_id in layers:
        log.info(
            "Creating %s catalog/schema and recording wiring: catalog=%s schema=%s storage_account=%s access_connector_id=%s principal_client_id=%s",
            layer_name,
            catalog,
            schema,
            storage_account,
            access_connector_id,
            principal_client_id,
        )
        _create_catalog_and_schema(spark, catalog, schema)

    log.info("Setup complete")


if __name__ == "__main__":
    main()