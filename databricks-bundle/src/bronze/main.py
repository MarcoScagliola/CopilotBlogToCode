"""Build bronze layer tables from raw source records."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
  parser = argparse.ArgumentParser(description="Bronze layer load")
  parser.add_argument("--catalog", required=True, help="Bronze catalog")
  parser.add_argument("--schema", required=True, help="Bronze schema")
  parser.add_argument("--secret-scope", required=True, help="Secret scope name")
  args = parser.parse_args()

  spark = SparkSession.builder.getOrCreate()
  table_name = f"`{args.catalog}`.`{args.schema}`.`raw_events`"

  # Placeholder bronze ingestion data for first-run validation.
  df = spark.range(1, 11).withColumn("ingest_ts", F.current_timestamp())
  df.write.mode("overwrite").saveAsTable(table_name)

  log.info("Bronze table refreshed: %s", table_name)


if __name__ == "__main__":
  main()