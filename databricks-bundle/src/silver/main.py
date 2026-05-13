"""Transform bronze data into curated silver records."""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Create silver table from bronze")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`transactions_bronze`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`transactions_silver`"

    df = spark.table(source_table)
    curated = df.filter(F.col("amount") > 0).withColumn(
        "amount_bucket", F.when(F.col("amount") >= 150, F.lit("high")).otherwise(F.lit("standard"))
    )
    curated.write.mode("overwrite").format("delta").saveAsTable(target_table)

    log.info("Silver table ready: %s", target_table)


if __name__ == "__main__":
    main()
