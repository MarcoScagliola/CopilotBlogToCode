import argparse

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create medallion catalogs and schemas.")
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


def ensure_namespace(spark: SparkSession, catalog: str, schema: str) -> None:
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    ensure_namespace(spark, args.bronze_catalog, args.bronze_schema)
    ensure_namespace(spark, args.silver_catalog, args.silver_schema)
    ensure_namespace(spark, args.gold_catalog, args.gold_schema)

    print("Setup completed for medallion catalogs and schemas.")


if __name__ == "__main__":
    main()