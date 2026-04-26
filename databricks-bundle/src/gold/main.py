import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold aggregation layer.")
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.silver_catalog}.{args.silver_schema}.events"
    target_table = f"{args.gold_catalog}.{args.gold_schema}.event_summary"

    silver_df = spark.table(source_table)

    gold_df = (
        silver_df.groupBy("event_type")
        .agg(
            F.count("*").alias("event_count"),
            F.sum("amount").alias("amount_total"),
            F.max("event_time_utc").alias("last_event_time_utc"),
        )
        .withColumn("aggregated_at_utc", F.current_timestamp())
    )

    gold_df.write.mode("overwrite").saveAsTable(target_table)
    print(f"Gold write complete: {target_table}")


if __name__ == "__main__":
    main()
