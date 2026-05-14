from __future__ import annotations

import argparse
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Setup Unity Catalog objects for secure medallion layers.")
    parser.add_argument("--workspace-resource-id", required=True)
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
    parser.add_argument("--bronze-principal-client-id", required=True)
    parser.add_argument("--silver-principal-client-id", required=True)
    parser.add_argument("--gold-principal-client-id", required=True)
    return parser.parse_args()


def ensure_catalog_schema(spark: SparkSession, catalog: str, schema: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    ensure_catalog_schema(spark, args.bronze_catalog, args.bronze_schema)
    ensure_catalog_schema(spark, args.silver_catalog, args.silver_schema)
    ensure_catalog_schema(spark, args.gold_catalog, args.gold_schema)

    # External location and storage credential naming is deterministic so repeated runs stay idempotent.
    spark.sql(
        f"""
        CREATE STORAGE CREDENTIAL IF NOT EXISTS bronze_credential
        WITH AZURE_MANAGED_IDENTITY '{args.bronze_access_connector_id}'
        """
    )
    spark.sql(
        f"""
        CREATE STORAGE CREDENTIAL IF NOT EXISTS silver_credential
        WITH AZURE_MANAGED_IDENTITY '{args.silver_access_connector_id}'
        """
    )
    spark.sql(
        f"""
        CREATE STORAGE CREDENTIAL IF NOT EXISTS gold_credential
        WITH AZURE_MANAGED_IDENTITY '{args.gold_access_connector_id}'
        """
    )

    spark.sql(
        f"""
        CREATE EXTERNAL LOCATION IF NOT EXISTS bronze_location
        URL 'abfss://bronze@{args.bronze_storage_account}.dfs.core.windows.net/'
        WITH (STORAGE CREDENTIAL bronze_credential)
        """
    )
    spark.sql(
        f"""
        CREATE EXTERNAL LOCATION IF NOT EXISTS silver_location
        URL 'abfss://silver@{args.silver_storage_account}.dfs.core.windows.net/'
        WITH (STORAGE CREDENTIAL silver_credential)
        """
    )
    spark.sql(
        f"""
        CREATE EXTERNAL LOCATION IF NOT EXISTS gold_location
        URL 'abfss://gold@{args.gold_storage_account}.dfs.core.windows.net/'
        WITH (STORAGE CREDENTIAL gold_credential)
        """
    )

    spark.sql(f"GRANT USE CATALOG ON CATALOG {args.bronze_catalog} TO `{args.bronze_principal_client_id}`")
    spark.sql(f"GRANT USE CATALOG ON CATALOG {args.silver_catalog} TO `{args.silver_principal_client_id}`")
    spark.sql(f"GRANT USE CATALOG ON CATALOG {args.gold_catalog} TO `{args.gold_principal_client_id}`")


if __name__ == "__main__":
    main()
