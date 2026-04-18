import argparse

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()
    bronze_table = f"{args.bronze_catalog}.{args.bronze_schema}.raw_events"
    silver_table = f"{args.silver_catalog}.{args.silver_schema}.events"
    bronze_df = spark.table(bronze_table)
    refined_df = bronze_df.dropDuplicates(["raw_id"])
    refined_df.write.mode("overwrite").saveAsTable(silver_table)


if __name__ == "__main__":
    main()
