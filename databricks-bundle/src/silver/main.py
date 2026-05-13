"""Transform bronze records into curated silver tables."""

import argparse
import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build curated silver table from bronze source.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`orders_raw`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`orders_curated`"

    transformed = (
        spark.table(source_table)
        .withColumn("order_date", to_date(col("order_date")))
        .withColumn("amount", col("amount").cast("double"))
    )

    transformed.write.mode("overwrite").saveAsTable(target_table)
    log.info("Wrote silver records to %s", target_table)


if __name__ == "__main__":
    main()
