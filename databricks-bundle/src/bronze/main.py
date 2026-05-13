"""Build a bronze layer seed table for secure medallion pipelines."""

import argparse
import logging

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Populate bronze sample table")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    table_name = f"`{args.catalog}`.`{args.schema}`.`transactions_bronze`"

    data = [
        (1, "A100", 120.5, "GBP"),
        (2, "B200", 99.9, "GBP"),
        (3, "C300", 240.0, "GBP"),
    ]
    df = spark.createDataFrame(data, ["id", "account_id", "amount", "currency"])
    df.write.mode("overwrite").format("delta").saveAsTable(table_name)

    log.info("Bronze table ready: %s using secret scope %s", table_name, args.secret_scope)


if __name__ == "__main__":
    main()
