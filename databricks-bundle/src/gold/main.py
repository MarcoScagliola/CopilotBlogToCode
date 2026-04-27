"""Aggregate Silver events into a Gold summary table."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import count, current_timestamp, sum

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Aggregate Silver events into a Gold summary table.")
    parser.add_argument("--source-catalog", required=True, help="Source Silver catalog")
    parser.add_argument("--source-schema", required=True, help="Source Silver schema")
    parser.add_argument("--target-catalog", required=True, help="Target Gold catalog")
    parser.add_argument("--target-schema", required=True, help="Target Gold schema")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`events`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`event_summary`"

    gold_df = (
        spark.table(source_table)
        .groupBy("event_type")
        .agg(
            count("*").alias("event_count"),
            sum("amount").alias("total_amount"),
        )
        .withColumn("aggregated_at", current_timestamp())
    )

    log.info("Writing Gold summary to %s", target_table)
    gold_df.write.mode("overwrite").saveAsTable(target_table)
    log.info("Gold aggregation complete with %s rows", gold_df.count())


if __name__ == "__main__":
    main()