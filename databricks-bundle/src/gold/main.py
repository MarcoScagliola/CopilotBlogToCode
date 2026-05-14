"""Aggregate silver records into gold analytics-ready facts."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
  parser = argparse.ArgumentParser(description="Gold layer aggregate")
  parser.add_argument("--source-catalog", required=True, help="Source catalog")
  parser.add_argument("--source-schema", required=True, help="Source schema")
  parser.add_argument("--target-catalog", required=True, help="Target catalog")
  parser.add_argument("--target-schema", required=True, help="Target schema")
  args = parser.parse_args()

  spark = SparkSession.builder.getOrCreate()
  source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`refined_events`"
  target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`curated_metrics`"

  df = spark.table(source_table).groupBy().agg(F.count(F.lit(1)).alias("row_count"))
  df.write.mode("overwrite").saveAsTable(target_table)

  log.info("Gold table refreshed: %s", target_table)


if __name__ == "__main__":
  main()