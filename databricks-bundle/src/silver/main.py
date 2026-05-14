from __future__ import annotations

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver refinement task.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.events_bronze"
    target_table = f"{args.target_catalog}.{args.target_schema}.events_silver"

    source_df = spark.table(source_table)
    silver_df = (
        source_df
        .withColumn("event_time", F.to_timestamp("event_ts"))
        .dropDuplicates(["event_id"])
        .where(F.col("reading").isNotNull())
    )

    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.target_catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")

    silver_df.write.format("delta").mode("overwrite").saveAsTable(target_table)


if __name__ == "__main__":
    main()
