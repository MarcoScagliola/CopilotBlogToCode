from __future__ import annotations

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold curation task.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.events_silver"
    target_table = f"{args.target_catalog}.{args.target_schema}.device_hourly_gold"

    source_df = spark.table(source_table)
    gold_df = (
        source_df
        .withColumn("event_hour", F.date_trunc("hour", F.col("event_time")))
        .groupBy("device_id", "event_hour")
        .agg(
            F.count("event_id").alias("event_count"),
            F.avg("reading").alias("avg_reading"),
            F.max("reading").alias("max_reading"),
        )
    )

    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.target_catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")

    gold_df.write.format("delta").mode("overwrite").saveAsTable(target_table)


if __name__ == "__main__":
    main()
