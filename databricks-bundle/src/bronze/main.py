import argparse

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    df = spark.range(0, 10).withColumnRenamed("id", "raw_id")
    bronze_table = f"{args.catalog}.{args.schema}.raw_events"
    df.write.mode("overwrite").saveAsTable(bronze_table)


if __name__ == "__main__":
    main()
