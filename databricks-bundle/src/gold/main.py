"""Aggregate silver orders into gold-layer business metrics for curated analytics consumption."""

from __future__ import annotations

import argparse
import logging

from pyspark.sql import functions as F


LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Curate analytics-ready metrics in the gold medallion layer.")
    parser.add_argument("--source-catalog", required=True, help="Source Unity Catalog catalog.")
    parser.add_argument("--source-schema", required=True, help="Source Unity Catalog schema.")
    parser.add_argument("--target-catalog", required=True, help="Target Unity Catalog catalog.")
    parser.add_argument("--target-schema", required=True, help="Target Unity Catalog schema.")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`orders_silver`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`orders_gold_metrics`"

    metrics_df = (
        spark.table(source_table)
        .groupBy(F.current_date().alias("processing_date"))
        .agg(
            F.count("*").alias("order_count"),
            F.round(F.sum("order_total"), 2).alias("gross_sales"),
        )
    )

    metrics_df.write.mode("overwrite").format("delta").saveAsTable(target_table)
    LOG.info("Gold aggregation complete for %s", target_table)


if __name__ == "__main__":
    main()