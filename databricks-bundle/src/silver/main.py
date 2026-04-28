import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Transform Bronze to Silver")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-silver").getOrCreate()

    source_tbl = f"{args.source_catalog}.{args.source_schema}.events_bronze"
    target_tbl = f"{args.target_catalog}.{args.target_schema}.events_silver"

    df = spark.table(source_tbl)
    silver_df = (
        df.withColumn("event_date", F.to_date("event_ts"))
        .dropDuplicates(["event_id"])
        .select("event_id", "event_type", "user_id", "event_ts", "event_date")
    )

    silver_df.write.mode("overwrite").saveAsTable(target_tbl)
    spark.stop()


if __name__ == "__main__":
    main()
