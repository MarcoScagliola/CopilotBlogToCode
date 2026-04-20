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
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    catalogs = [args.bronze_catalog, args.silver_catalog, args.gold_catalog]
    schemas = [
        (args.bronze_catalog, args.bronze_schema),
        (args.silver_catalog, args.silver_schema),
        (args.gold_catalog, args.gold_schema),
    ]

    for catalog in catalogs:
        spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog}")
        print(f"Catalog ready: {catalog}")

    for catalog, schema in schemas:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")
        print(f"Schema ready: {catalog}.{schema}")


if __name__ == "__main__":
    main()
