"""Aggregate Silver events into Gold summary table."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _quote(identifier: str) -> str:
    return f"`{identifier}`"


def main() -> None:
    parser = argparse.ArgumentParser(description="Gold aggregation job.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("medallion-gold").getOrCreate()

    source_table = f"{_quote(args.source_catalog)}.{_quote(args.source_schema)}.{_quote('events')}"
    target_table = f"{_quote(args.target_catalog)}.{_quote(args.target_schema)}.{_quote('event_summary')}"

    summary = (
        spark.table(source_table)
        .groupBy("event_type")
        .agg(
            F.count("*").alias("event_count"),
            F.sum("amount").alias("total_amount"),
            F.max("refined_at_utc").alias("last_refined_at_utc"),
        )
    )

    summary.write.mode("overwrite").saveAsTable(target_table)
    log.info("Gold load complete: wrote %s rows to %s", summary.count(), target_table)


if __name__ == "__main__":
    main()
