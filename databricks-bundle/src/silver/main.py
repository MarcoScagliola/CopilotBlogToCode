import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver layer refinement job")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.raw_events"
    target_table = f"{args.target_catalog}.{args.target_schema}.events"

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")

    refined = (
        spark.table(source_table)
        .withColumn("event_date", F.to_date(F.col("event_time")))
        .dropDuplicates(["id"])
    )

    (
        refined.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )


if __name__ == "__main__":
    main()
