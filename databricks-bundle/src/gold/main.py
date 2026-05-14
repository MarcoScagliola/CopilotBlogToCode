"""Aggregate silver output into a gold metrics table for the medallion pipeline."""

import argparse
import logging

from pyspark.sql import SparkSession, functions as F

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

SOURCE_TABLE_NAME = "silver_layer_runs"
TARGET_TABLE_NAME = "gold_layer_metrics"


def _qualified_table(catalog: str, schema: str, table_name: str) -> str:
    return f"`{catalog}`.`{schema}`.`{table_name}`"


def main() -> None:
    parser = argparse.ArgumentParser(description="Read silver records and write a gold metrics table.")
    parser.add_argument("--source-catalog", required=True, help="Silver source catalog name.")
    parser.add_argument("--source-schema", required=True, help="Silver source schema name.")
    parser.add_argument("--target-catalog", required=True, help="Gold target catalog name.")
    parser.add_argument("--target-schema", required=True, help="Gold target schema name.")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = _qualified_table(args.source_catalog, args.source_schema, SOURCE_TABLE_NAME)
    target_table = _qualified_table(args.target_catalog, args.target_schema, TARGET_TABLE_NAME)

    log.info("Reading silver source table %s", source_table)
    silver_df = spark.table(source_table)
    silver_count = silver_df.count()

    gold_df = silver_df.select(
        F.lit("gold").alias("layer"),
        F.lit(args.source_catalog).alias("source_catalog"),
        F.lit(args.source_schema).alias("source_schema"),
        F.lit(silver_count).alias("silver_row_count"),
        F.current_timestamp().alias("generated_at"),
    )

    log.info("Writing gold metrics table %s from %s silver rows", target_table, silver_count)
    gold_df.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)
    log.info("Gold write complete")


if __name__ == "__main__":
    main()