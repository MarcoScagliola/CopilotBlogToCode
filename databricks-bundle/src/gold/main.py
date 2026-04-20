import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold layer curation job")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.events"
    target_table = f"{args.target_catalog}.{args.target_schema}.event_summary"

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")

    summary = (
        spark.table(source_table)
        .groupBy("event_date")
        .agg(F.count("*").alias("event_count"))
        .orderBy(F.col("event_date").desc())
    )

    (
        summary.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )


if __name__ == "__main__":
    main()
