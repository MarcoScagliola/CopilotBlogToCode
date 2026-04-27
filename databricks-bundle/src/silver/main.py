"""Transform Bronze raw events into a deduplicated Silver events table."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp, row_number
from pyspark.sql.window import Window

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Transform Bronze events into Silver events.")
    parser.add_argument("--source-catalog", required=True, help="Source Bronze catalog")
    parser.add_argument("--source-schema", required=True, help="Source Bronze schema")
    parser.add_argument("--target-catalog", required=True, help="Target Silver catalog")
    parser.add_argument("--target-schema", required=True, help="Target Silver schema")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`raw_events`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`events`"

    raw_df = spark.table(source_table)
    window = Window.partitionBy("event_id").orderBy(col("ingested_at").desc())
    silver_df = (
        raw_df.withColumn("row_num", row_number().over(window))
        .where(col("row_num") == 1)
        .drop("row_num")
        .withColumn("refined_at", current_timestamp())
    )

    log.info("Writing Silver events to %s", target_table)
    silver_df.write.mode("overwrite").saveAsTable(target_table)
    log.info("Silver transformation complete with %s rows", silver_df.count())


if __name__ == "__main__":
    main()