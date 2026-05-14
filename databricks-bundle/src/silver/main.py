"""Transform bronze records into silver business-conformed records."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
  parser = argparse.ArgumentParser(description="Silver layer transform")
  parser.add_argument("--source-catalog", required=True, help="Source catalog")
  parser.add_argument("--source-schema", required=True, help="Source schema")
  parser.add_argument("--target-catalog", required=True, help="Target catalog")
  parser.add_argument("--target-schema", required=True, help="Target schema")
  args = parser.parse_args()

  spark = SparkSession.builder.getOrCreate()
  source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`raw_events`"
  target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`refined_events`"

  df = spark.table(source_table).withColumn("quality_flag", F.lit("valid"))
  df.write.mode("overwrite").saveAsTable(target_table)

  log.info("Silver table refreshed: %s", target_table)


if __name__ == "__main__":
  main()