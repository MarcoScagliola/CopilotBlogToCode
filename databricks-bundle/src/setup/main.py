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
    return parser.parse_args()


def _managed_location(layer: str, storage_account: str, catalog: str) -> str:
    account = storage_account.strip()
    if not account:
        raise ValueError(f"Missing storage account for layer '{layer}'.")
    # Keep each catalog rooted in its own ADLS Gen2 filesystem for least privilege.
    return f"abfss://{layer}@{account}.dfs.core.windows.net/uc/{catalog}"


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    catalog_specs = [
        ("bronze", args.bronze_catalog, args.bronze_storage_account),
        ("silver", args.silver_catalog, args.silver_storage_account),
        ("gold", args.gold_catalog, args.gold_storage_account),
    ]

    schemas = [
        (args.bronze_catalog, args.bronze_schema),
        (args.silver_catalog, args.silver_schema),
        (args.gold_catalog, args.gold_schema),
    ]

    for layer, catalog, storage_account in catalog_specs:
        managed_location = _managed_location(layer, storage_account, catalog)
        spark.sql(
            f"CREATE CATALOG IF NOT EXISTS {catalog} "
            f"MANAGED LOCATION '{managed_location}'"
        )
        print(f"Catalog ready: {catalog} ({managed_location})")

    for catalog, schema in schemas:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")
        print(f"Schema ready: {catalog}.{schema}")


if __name__ == "__main__":
    main()
