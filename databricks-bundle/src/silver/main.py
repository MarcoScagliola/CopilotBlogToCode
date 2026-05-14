"""Transform bronze orders into a standardized silver dataset with basic data-quality enforcement."""

from __future__ import annotations

import argparse
import logging


LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Refine bronze records into the silver medallion layer.")
    parser.add_argument("--source-catalog", required=True, help="Source Unity Catalog catalog.")
    parser.add_argument("--source-schema", required=True, help="Source Unity Catalog schema.")
    parser.add_argument("--target-catalog", required=True, help="Target Unity Catalog catalog.")
    parser.add_argument("--target-schema", required=True, help="Target Unity Catalog schema.")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`orders_bronze`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`orders_silver`"

    df = spark.table(source_table)
    refined_df = (
        df.dropna(subset=["order_id", "customer_name", "order_total"])
        .dropDuplicates(["order_id"])
        .withColumnRenamed("customer_name", "customer_name_clean")
    )

    refined_df.write.mode("overwrite").format("delta").saveAsTable(target_table)
    LOG.info("Silver transformation complete for %s", target_table)


if __name__ == "__main__":
    main()