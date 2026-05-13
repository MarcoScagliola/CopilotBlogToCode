"""Aggregate silver records into gold analytical tables."""

import argparse
import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import count, sum

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build gold aggregates from silver source.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`orders_curated`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`daily_sales`"

    aggregated = (
        spark.table(source_table)
        .groupBy("order_date")
        .agg(sum("amount").alias("total_amount"), count("order_id").alias("order_count"))
    )

    aggregated.write.mode("overwrite").saveAsTable(target_table)
    log.info("Wrote gold aggregates to %s", target_table)


if __name__ == "__main__":
    main()
