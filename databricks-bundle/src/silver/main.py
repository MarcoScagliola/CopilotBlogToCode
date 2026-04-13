import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver transform job")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--source-table", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    parser.add_argument("--target-table", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.{args.source_table}"
    target_table = f"{args.target_catalog}.{args.target_schema}.{args.target_table}"

    source_df = spark.table(source_table)
    cleaned_df = (
        source_df.dropDuplicates()
        .withColumn("_processed_at", F.current_timestamp())
        .withColumn("_record_hash", F.sha2(F.to_json(F.struct(*source_df.columns)), 256))
    )

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")
    cleaned_df.write.mode("overwrite").format("delta").saveAsTable(target_table)
    print(f"Silver transform complete: {target_table}")


if __name__ == "__main__":
    main()