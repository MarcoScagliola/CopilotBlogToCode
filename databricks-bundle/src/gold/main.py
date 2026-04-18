import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()
    silver_table = f"{args.silver_catalog}.{args.silver_schema}.events"
    gold_table = f"{args.gold_catalog}.{args.gold_schema}.event_summary"
    silver_df = spark.table(silver_table)
    gold_df = silver_df.groupBy().agg(F.count("raw_id").alias("event_count"))
    gold_df.write.mode("overwrite").saveAsTable(gold_table)


if __name__ == "__main__":
    main()
