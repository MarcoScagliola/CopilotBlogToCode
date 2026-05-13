"""Create medallion catalogs and schemas used by downstream jobs."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _create_catalog_and_schema(spark: SparkSession, catalog: str, schema: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema}`")


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup Unity Catalog objects for medallion layers")
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

    spark = SparkSession.builder.getOrCreate()

    _create_catalog_and_schema(spark, args.bronze_catalog, args.bronze_schema)
    _create_catalog_and_schema(spark, args.silver_catalog, args.silver_schema)
    _create_catalog_and_schema(spark, args.gold_catalog, args.gold_schema)

    log.info("Setup completed for bronze=%s silver=%s gold=%s", args.bronze_catalog, args.silver_catalog, args.gold_catalog)


if __name__ == "__main__":
    main()
