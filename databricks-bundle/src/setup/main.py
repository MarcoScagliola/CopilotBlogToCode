"""Initialize medallion catalogs and schemas required by downstream jobs."""

import argparse
import logging


log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _create_namespace(catalog: str, schema: str) -> None:
    statement = f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema}`"
    log.info("Prepared statement: %s", statement)


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup medallion catalog and schema scaffolding.")
    parser.add_argument("--workspace-resource-id", required=True, help="Databricks workspace resource ID.")
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
    parser.add_argument("--bronze-principal-client-id", required=True, help="Bronze principal client ID.")
    parser.add_argument("--silver-principal-client-id", required=True, help="Silver principal client ID.")
    parser.add_argument("--gold-principal-client-id", required=True, help="Gold principal client ID.")
    args = parser.parse_args()

    log.info("Setup started for workspace %s", args.workspace_resource_id)
    _create_namespace(args.bronze_catalog, args.bronze_schema)
    _create_namespace(args.silver_catalog, args.silver_schema)
    _create_namespace(args.gold_catalog, args.gold_schema)
    log.info("Setup completed")


if __name__ == "__main__":
    main()
