"""Transform bronze records into a compact silver summary for the medallion pipeline."""

import argparse
import logging

from pyspark.sql import SparkSession, functions as F

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

SOURCE_TABLE_NAME = "bronze_layer_runs"
TARGET_TABLE_NAME = "silver_layer_runs"


def _qualified_table(catalog: str, schema: str, table_name: str) -> str:
    return f"`{catalog}`.`{schema}`.`{table_name}`"


def main() -> None:
    parser = argparse.ArgumentParser(description="Read bronze records and write a silver summary.")
    parser.add_argument("--source-catalog", required=True, help="Bronze source catalog name.")
    parser.add_argument("--source-schema", required=True, help="Bronze source schema name.")
    parser.add_argument("--target-catalog", required=True, help="Silver target catalog name.")
    parser.add_argument("--target-schema", required=True, help="Silver target schema name.")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = _qualified_table(args.source_catalog, args.source_schema, SOURCE_TABLE_NAME)
    target_table = _qualified_table(args.target_catalog, args.target_schema, TARGET_TABLE_NAME)

    log.info("Reading bronze source table %s", source_table)
    bronze_df = spark.table(source_table)
    bronze_count = bronze_df.count()

    summary_df = bronze_df.select(
        F.lit("silver").alias("layer"),
        F.lit(args.source_catalog).alias("source_catalog"),
        F.lit(args.source_schema).alias("source_schema"),
        F.lit(bronze_count).alias("bronze_row_count"),
        F.current_timestamp().alias("processed_at"),
    )

    log.info("Writing silver summary table %s from %s bronze rows", target_table, bronze_count)
    summary_df.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)
    log.info("Silver write complete")


if __name__ == "__main__":
    main()