"""Create medallion catalogs and schemas for setup stage."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _quote(identifier: str) -> str:
    return f"`{identifier}`"


def _create_catalog_and_schema(spark: SparkSession, catalog: str, schema: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {_quote(catalog)}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {_quote(catalog)}.{_quote(schema)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup catalogs and schemas for medallion layers.")
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
    args = parser.parse_args()

    spark = SparkSession.builder.appName("medallion-setup").getOrCreate()

    _create_catalog_and_schema(spark, args.bronze_catalog, args.bronze_schema)
    _create_catalog_and_schema(spark, args.silver_catalog, args.silver_schema)
    _create_catalog_and_schema(spark, args.gold_catalog, args.gold_schema)

    log.info(
        "Setup complete. Storage by layer: bronze=%s silver=%s gold=%s",
        args.bronze_storage_account,
        args.silver_storage_account,
        args.gold_storage_account,
    )
    log.info(
        "Access connector IDs by layer: bronze=%s silver=%s gold=%s",
        args.bronze_access_connector_id,
        args.silver_access_connector_id,
        args.gold_access_connector_id,
    )


if __name__ == "__main__":
    main()
