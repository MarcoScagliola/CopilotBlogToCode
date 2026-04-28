"""Aggregate Silver events into Gold daily facts."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Aggregate Silver data into Gold")
    parser.add_argument("--source-catalog", required=True, help="Source catalog name")
    parser.add_argument("--source-schema", required=True, help="Source schema name")
    parser.add_argument("--target-catalog", required=True, help="Target catalog name")
    parser.add_argument("--target-schema", required=True, help="Target schema name")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("secure-medallion-gold").getOrCreate()
    source_table = f"{args.source_catalog}.{args.source_schema}.events_silver"
    target_table = f"{args.target_catalog}.{args.target_schema}.event_type_daily_gold"

    df = spark.table(source_table)
    gold_df = df.groupBy("event_date", "event_type").agg(F.count("*").alias("event_count"))

    gold_df.write.mode("overwrite").saveAsTable(target_table)
    spark.stop()
    log.info("Gold aggregation complete")


if __name__ == "__main__":
    main()
