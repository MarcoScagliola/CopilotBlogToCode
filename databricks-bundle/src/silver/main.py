"""Refine Bronze events into Silver table with deduplication."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _quote(identifier: str) -> str:
    return f"`{identifier}`"


def main() -> None:
    parser = argparse.ArgumentParser(description="Silver refinement job.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("medallion-silver").getOrCreate()

    source_table = f"{_quote(args.source_catalog)}.{_quote(args.source_schema)}.{_quote('raw_events')}"
    target_table = f"{_quote(args.target_catalog)}.{_quote(args.target_schema)}.{_quote('events')}"

    df = spark.table(source_table).dropDuplicates(["event_id"])
    refined = df.withColumn("refined_at_utc", F.current_timestamp())

    refined.write.mode("overwrite").saveAsTable(target_table)
    log.info("Silver load complete: wrote %s rows to %s", refined.count(), target_table)


if __name__ == "__main__":
    main()
