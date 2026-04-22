import argparse
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Catalog and schema setup job")
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


def _managed_location(layer: str, storage_account: str, catalog: str) -> str:
    account = storage_account.strip()
    if not account:
        raise ValueError(f"Missing storage account for layer '{layer}'.")
    # Keep each catalog rooted in its own ADLS Gen2 filesystem for least privilege.
    return f"abfss://{layer}@{account}.dfs.core.windows.net/uc/{catalog}"


def _require_non_empty(label: str, value: str) -> str:
    normalized = value.strip()
    if not normalized:
        raise ValueError(f"Missing required value for {label}.")
    return normalized


def _uc_object_name(prefix: str, catalog: str) -> str:
    # UC identifiers cannot contain hyphens unless quoted. Keep deterministic safe names.
    safe_catalog = catalog.strip().lower().replace("-", "_")
    return f"{prefix}_{safe_catalog}"


def _create_storage_credential(
    spark: SparkSession,
    storage_credential_name: str,
    access_connector_id: str,
) -> None:
    spark.sql(
        f"CREATE STORAGE CREDENTIAL IF NOT EXISTS {storage_credential_name} "
        f"WITH AZURE_MANAGED_IDENTITY (ACCESS_CONNECTOR_ID = '{access_connector_id}')"
    )
    print(f"Storage credential ready: {storage_credential_name}")


def _create_external_location(
    spark: SparkSession,
    external_location_name: str,
    managed_location: str,
    storage_credential_name: str,
) -> None:
    spark.sql(
        f"CREATE EXTERNAL LOCATION IF NOT EXISTS {external_location_name} "
        f"URL '{managed_location}' "
        f"WITH (STORAGE CREDENTIAL {storage_credential_name})"
    )
    print(f"External location ready: {external_location_name} ({managed_location})")


def _create_catalog(spark: SparkSession, catalog: str, managed_location: str) -> None:
    spark.sql(
        f"CREATE CATALOG IF NOT EXISTS {catalog} "
        f"MANAGED LOCATION '{managed_location}'"
    )
    print(f"Catalog ready: {catalog} ({managed_location})")


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    catalog_specs = [
        (
            "bronze",
            args.bronze_catalog,
            args.bronze_storage_account,
            args.bronze_access_connector_id,
        ),
        (
            "silver",
            args.silver_catalog,
            args.silver_storage_account,
            args.silver_access_connector_id,
        ),
        (
            "gold",
            args.gold_catalog,
            args.gold_storage_account,
            args.gold_access_connector_id,
        ),
    ]

    schemas = [
        (args.bronze_catalog, args.bronze_schema),
        (args.silver_catalog, args.silver_schema),
        (args.gold_catalog, args.gold_schema),
    ]

    for layer, catalog, storage_account, access_connector_id in catalog_specs:
        managed_location = _managed_location(layer, storage_account, catalog)
        credential_name = _uc_object_name("sc", catalog)
        external_location_name = _uc_object_name("el", catalog)

        normalized_connector_id = _require_non_empty(
            f"{layer} access connector id", access_connector_id
        )
        _create_storage_credential(spark, credential_name, normalized_connector_id)
        _create_external_location(
            spark,
            external_location_name,
            managed_location,
            credential_name,
        )
        _create_catalog(spark, catalog, managed_location)

    for catalog, schema in schemas:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")
        print(f"Schema ready: {catalog}.{schema}")


if __name__ == "__main__":
    main()
