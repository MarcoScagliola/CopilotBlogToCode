import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold publish job")
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

    if "event_time" in source_df.columns:
        event_ts = F.to_timestamp("event_time")
    elif "_ingested_at" in source_df.columns:
        event_ts = F.to_timestamp("_ingested_at")
    else:
        event_ts = F.current_timestamp()

    metrics_df = (
        source_df.withColumn("event_ts", event_ts)
        .withColumn("event_date", F.to_date("event_ts"))
        .groupBy("event_date")
        .agg(
            F.count(F.lit(1)).alias("record_count"),
            F.max("event_ts").alias("latest_event_ts")
        )
        .orderBy("event_date")
    )

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.target_catalog}.{args.target_schema}")
    metrics_df.write.mode("overwrite").format("delta").saveAsTable(target_table)
    print(f"Gold publish complete: {target_table}")


if __name__ == "__main__":
    main()