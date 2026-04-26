import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver refinement layer.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.bronze_catalog}.{args.bronze_schema}.raw_events"
    target_table = f"{args.silver_catalog}.{args.silver_schema}.events"

    bronze_df = spark.table(source_table)

    silver_df = (
        bronze_df.orderBy(F.col("event_time_utc").desc())
        .dropDuplicates(["event_id"])
        .withColumn("refined_at_utc", F.current_timestamp())
    )

    silver_df.write.mode("overwrite").saveAsTable(target_table)
    print(f"Silver write complete: {target_table}")


if __name__ == "__main__":
    main()
