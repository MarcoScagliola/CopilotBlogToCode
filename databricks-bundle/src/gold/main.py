from __future__ import annotations

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import coalesce, col, count, current_timestamp, date_trunc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold curation job")
    parser.add_argument("--input-catalog", required=True)
    parser.add_argument("--input-schema", required=True)
    parser.add_argument("--input-table", required=True)
    parser.add_argument("--output-catalog", required=True)
    parser.add_argument("--output-schema", required=True)
    parser.add_argument("--output-table", required=True)
    return parser.parse_args()


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-gold").getOrCreate()

    input_table = f"{args.input_catalog}.{args.input_schema}.{args.input_table}"
    output_table = f"{args.output_catalog}.{args.output_schema}.{args.output_table}"

    logging.info("Curating Silver managed table %s", input_table)
    curated = (
        spark.table(input_table)
        .withColumn("event_day", date_trunc("day", coalesce(col("refined_at"), current_timestamp())))
        .groupBy("event_day")
        .agg(count("*").alias("record_count"))
        .withColumn("curated_at", current_timestamp())
    )

    logging.info("Writing Gold managed table %s", output_table)
    curated.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(output_table)


if __name__ == "__main__":
    main()