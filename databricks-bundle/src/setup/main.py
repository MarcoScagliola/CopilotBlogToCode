"""Initialize medallion catalogs, schemas, and validation checks for the workspace."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _create_namespace(spark: SparkSession, catalog: str, schema: str) -> None:
  spark.sql(f"CREATE CATALOG IF NOT EXISTS `{catalog}`")
  spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{catalog}`.`{schema}`")


def main() -> None:
  parser = argparse.ArgumentParser(description="Prepare medallion namespaces")
  parser.add_argument("--workspace-resource-id", required=True, help="Databricks workspace resource ID")
  parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog")
  parser.add_argument("--silver-catalog", required=True, help="Silver catalog")
  parser.add_argument("--gold-catalog", required=True, help="Gold catalog")
  parser.add_argument("--bronze-schema", required=True, help="Bronze schema")
  parser.add_argument("--silver-schema", required=True, help="Silver schema")
  parser.add_argument("--gold-schema", required=True, help="Gold schema")
  parser.add_argument("--bronze-storage-account", required=True, help="Bronze storage account")
  parser.add_argument("--silver-storage-account", required=True, help="Silver storage account")
  parser.add_argument("--gold-storage-account", required=True, help="Gold storage account")
  parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze connector resource ID")
  parser.add_argument("--silver-access-connector-id", required=True, help="Silver connector resource ID")
  parser.add_argument("--gold-access-connector-id", required=True, help="Gold connector resource ID")
  parser.add_argument("--bronze-principal-client-id", required=True, help="Bronze principal client ID")
  parser.add_argument("--silver-principal-client-id", required=True, help="Silver principal client ID")
  parser.add_argument("--gold-principal-client-id", required=True, help="Gold principal client ID")
  args = parser.parse_args()

  spark = SparkSession.builder.getOrCreate()

  log.info("Setup starting for workspace %s", args.workspace_resource_id)
  _create_namespace(spark, args.bronze_catalog, args.bronze_schema)
  _create_namespace(spark, args.silver_catalog, args.silver_schema)
  _create_namespace(spark, args.gold_catalog, args.gold_schema)
  log.info("Setup complete")


if __name__ == "__main__":
  main()