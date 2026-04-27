"""Create the catalogs and schemas required by the secure medallion sample."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _ensure_namespace(spark: SparkSession, catalog: str, schema_name: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema_name}`")


def main() -> None:
    parser = argparse.ArgumentParser(description="Prepare Unity Catalog objects for the medallion layers.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze storage account name")
    parser.add_argument("--silver-storage-account", required=True, help="Silver storage account name")
    parser.add_argument("--gold-storage-account", required=True, help="Gold storage account name")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze access connector ID")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver access connector ID")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold access connector ID")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    log.info("Preparing catalogs and schemas")
    _ensure_namespace(spark, args.bronze_catalog, args.bronze_schema)
    _ensure_namespace(spark, args.silver_catalog, args.silver_schema)
    _ensure_namespace(spark, args.gold_catalog, args.gold_schema)

    log.info(
        "Setup context: bronze_storage=%s silver_storage=%s gold_storage=%s",
        args.bronze_storage_account,
        args.silver_storage_account,
        args.gold_storage_account,
    )
    log.info(
        "Access connectors: bronze=%s silver=%s gold=%s",
        args.bronze_access_connector_id,
        args.silver_access_connector_id,
        args.gold_access_connector_id,
    )
    log.info("Catalog and schema setup complete")


if __name__ == "__main__":
    main()