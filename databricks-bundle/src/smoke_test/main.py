"""Verify the medallion tables exist and contain data after the jobs finish."""

import argparse
import logging

from pyspark.sql import SparkSession

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

BRONZE_TABLE_NAME = "bronze_layer_runs"
SILVER_TABLE_NAME = "silver_layer_runs"
GOLD_TABLE_NAME = "gold_layer_metrics"


def _qualified_table(catalog: str, schema: str, table_name: str) -> str:
    return f"`{catalog}`.`{schema}`.`{table_name}`"


def _count_table(spark: SparkSession, catalog: str, schema: str, table_name: str) -> int:
    qualified = _qualified_table(catalog, schema, table_name)
    count = spark.table(qualified).count()
    log.info("Table %s has %s row(s)", qualified, count)
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate the medallion pipeline outputs.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name.")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name.")
    parser.add_argument("--min-row-count", type=int, required=True, help="Minimum row count expected in each table.")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    bronze_count = _count_table(spark, args.bronze_catalog, args.bronze_schema, BRONZE_TABLE_NAME)
    silver_count = _count_table(spark, args.silver_catalog, args.silver_schema, SILVER_TABLE_NAME)
    gold_count = _count_table(spark, args.gold_catalog, args.gold_schema, GOLD_TABLE_NAME)

    for layer_name, count in [("bronze", bronze_count), ("silver", silver_count), ("gold", gold_count)]:
        if count < args.min_row_count:
            raise RuntimeError(f"{layer_name} table has {count} row(s), expected at least {args.min_row_count}")

    log.info("Smoke test complete")


if __name__ == "__main__":
    main()