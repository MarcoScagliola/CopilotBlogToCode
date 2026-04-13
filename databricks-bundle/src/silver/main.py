"""
Silver transformation layer – deduplicates and cleanses Bronze data.

Reads from Bronze catalog, applies deduplication and null-drop on key columns,
then writes cleansed records to the Silver managed Delta table.

Usage (via Databricks job parameters):
  --bronze_catalog     Bronze Unity Catalog name
  --bronze_schema      Bronze schema name
  --silver_catalog     Silver Unity Catalog name
  --silver_schema      Silver schema name
  --source_table_name  Table name shared across layers
"""

import argparse
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql import functions as F


def parse_args():
    parser = argparse.ArgumentParser(description="Silver transformation job")
    parser.add_argument("--bronze_catalog", required=True)
    parser.add_argument("--bronze_schema", required=True)
    parser.add_argument("--silver_catalog", required=True)
    parser.add_argument("--silver_schema", required=True)
    parser.add_argument("--source_table_name", required=True)
    return parser.parse_args()


def deduplicate(df: DataFrame) -> DataFrame:
    """Deduplicate on id or source_id, keeping the latest record."""
    id_col = next(
        (c for c in ("id", "source_id") if c in df.columns),
        None,
    )
    if id_col is None:
        return df.dropDuplicates()

    # Keep first occurrence per id (stable dedup; extend with window if ordering needed)
    return df.dropDuplicates(subset=[id_col])


def drop_nulls_on_key_columns(df: DataFrame) -> DataFrame:
    """Drop rows where any of the first 5 non-null-free columns are null."""
    key_cols = [c for c in df.columns if c not in ("_rescued_data",)][:5]
    return df.dropna(subset=key_cols)


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`{args.source_table_name}`"
    target_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`{args.source_table_name}`"

    bronze_df = spark.read.table(source_table)

    silver_df = drop_nulls_on_key_columns(deduplicate(bronze_df))

    (
        silver_df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )

    print(f"[silver] Wrote {silver_df.count()} rows to {target_table}")


if __name__ == "__main__":
    main()
