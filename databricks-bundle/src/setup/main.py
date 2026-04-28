"""Create Medallion catalogs and schemas for Bronze, Silver, and Gold."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Create Medallion catalogs and schemas")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze storage account name")
    parser.add_argument("--silver-storage-account", required=True, help="Silver storage account name")
    parser.add_argument("--gold-storage-account", required=True, help="Gold storage account name")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze access connector id")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver access connector id")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold access connector id")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("secure-medallion-setup").getOrCreate()
    log.info("Creating catalogs and schemas")

    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{args.bronze_catalog}`")
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{args.silver_catalog}`")
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{args.gold_catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{args.bronze_catalog}`.`{args.bronze_schema}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{args.silver_catalog}`.`{args.silver_schema}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{args.gold_catalog}`.`{args.gold_schema}`")

    spark.stop()
    log.info("Setup complete")


if __name__ == "__main__":
    main()
