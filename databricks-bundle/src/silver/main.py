"""Transform Bronze events into a deduplicated Silver table."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Transform Bronze data into Silver")
    parser.add_argument("--source-catalog", required=True, help="Source catalog name")
    parser.add_argument("--source-schema", required=True, help="Source schema name")
    parser.add_argument("--target-catalog", required=True, help="Target catalog name")
    parser.add_argument("--target-schema", required=True, help="Target schema name")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("secure-medallion-silver").getOrCreate()
    source_table = f"{args.source_catalog}.{args.source_schema}.events_bronze"
    target_table = f"{args.target_catalog}.{args.target_schema}.events_silver"

    log.info("Reading %s", source_table)
    df = spark.table(source_table)
    silver_df = (
        df.withColumn("event_date", F.to_date("event_ts"))
        .dropDuplicates(["event_id"])
        .select("event_id", "event_type", "user_id", "event_ts", "event_date")
    )

    silver_df.write.mode("overwrite").saveAsTable(target_table)
    spark.stop()
    log.info("Silver transformation complete")


if __name__ == "__main__":
    main()
