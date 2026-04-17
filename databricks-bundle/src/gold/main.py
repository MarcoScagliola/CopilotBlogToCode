import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, current_timestamp, max as spark_max


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

    source = f"`{args.silver_catalog}`.`{args.silver_schema}`.`source_refined`"
    target = f"`{args.gold_catalog}`.`{args.gold_schema}`.`source_daily_summary`"

    df = spark.read.table(source)
    summary = (
        df.groupBy(col("event_date"))
        .agg(count("*").alias("record_count"), spark_max("_refined_at").alias("last_refined_at"))
        .withColumn("_curated_at", current_timestamp())
    )

    summary.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target)


if __name__ == "__main__":
    main()
