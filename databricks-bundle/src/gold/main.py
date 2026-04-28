import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Aggregate Silver to Gold")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-gold").getOrCreate()

    source_tbl = f"{args.source_catalog}.{args.source_schema}.events_silver"
    target_tbl = f"{args.target_catalog}.{args.target_schema}.event_type_daily_gold"

    df = spark.table(source_tbl)
    gold_df = (
        df.groupBy("event_date", "event_type")
        .agg(F.count("*").alias("event_count"))
        .orderBy("event_date", "event_type")
    )

    gold_df.write.mode("overwrite").saveAsTable(target_tbl)
    spark.stop()


if __name__ == "__main__":
    main()
