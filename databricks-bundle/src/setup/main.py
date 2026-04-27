"""Setup job entrypoint for medallion namespaces."""

import argparse
from pyspark.sql import SparkSession


def main() -> None:
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
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.bronze_catalog}")
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.silver_catalog}")
    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.gold_catalog}")

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.bronze_catalog}.{args.bronze_schema}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.silver_catalog}.{args.silver_schema}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.gold_catalog}.{args.gold_schema}")

    print("Setup completed.")


if __name__ == "__main__":
    main()