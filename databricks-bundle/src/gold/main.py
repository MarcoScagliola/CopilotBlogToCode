import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold aggregation layer.")
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

    summary = (
        spark.table(source_table)
        .groupBy("event_type")
        .agg(
            F.count("*").alias("event_count"),
            F.sum("amount").alias("total_amount"),
            F.avg("amount").alias("avg_amount"),
        )
    )

    summary.write.mode("overwrite").saveAsTable(target_table)
    print(f"Gold write complete: {target_table}")


if __name__ == "__main__":
    main()