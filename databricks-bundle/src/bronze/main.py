"""Ingest source records into bronze layer managed tables."""

import argparse
import logging
from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load bronze sample dataset.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    target_table = f"`{args.catalog}`.`{args.schema}`.`orders_raw`"

    dataset = [
        ("o-1001", "c-001", 125.5, "2026-05-01"),
        ("o-1002", "c-002", 89.9, "2026-05-01"),
        ("o-1003", "c-001", 45.0, "2026-05-02"),
    ]
    df = spark.createDataFrame(dataset, ["order_id", "customer_id", "amount", "order_date"])

    df.write.mode("overwrite").saveAsTable(target_table)
    log.info("Wrote bronze records to %s using scope %s", target_table, args.secret_scope)


if __name__ == "__main__":
    main()
