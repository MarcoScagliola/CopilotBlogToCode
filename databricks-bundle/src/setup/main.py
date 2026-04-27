import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Setup: create catalogs and schemas for Medallion layers.")
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


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    catalogs = [
        (args.bronze_catalog, "Bronze layer managed tables"),
        (args.silver_catalog, "Silver layer managed tables"),
        (args.gold_catalog, "Gold layer managed tables"),
    ]
    schemas = [
        (args.bronze_catalog, args.bronze_schema, "Bronze schema"),
        (args.silver_catalog, args.silver_schema, "Silver schema"),
        (args.gold_catalog, args.gold_schema, "Gold schema"),
    ]

    # Create catalogs
    for catalog, comment in catalogs:
        spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog} COMMENT '{comment}'")
        print(f"Catalog created/verified: {catalog}")

    # Create schemas
    for catalog, schema, comment in schemas:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema} COMMENT '{comment}'")
        print(f"Schema created/verified: {catalog}.{schema}")

    print("Setup complete: all catalogs and schemas created")


if __name__ == "__main__":
    main()
