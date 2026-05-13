"""Aggregate silver data into gold analytics metrics."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Create gold aggregate table")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`transactions_silver`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`transactions_gold`"

    agg = (
        spark.table(source_table)
        .groupBy("currency", "amount_bucket")
        .agg(F.count(F.lit(1)).alias("row_count"), F.round(F.sum("amount"), 2).alias("total_amount"))
    )
    agg.write.mode("overwrite").format("delta").saveAsTable(target_table)

    log.info("Gold table ready: %s", target_table)


if __name__ == "__main__":
    main()
