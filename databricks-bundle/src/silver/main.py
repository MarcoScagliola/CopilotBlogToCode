"""
Silver Layer – Refinement
Reads from the Bronze catalog, deduplicates, drops nulls, and writes
cleansed records to the Silver Unity Catalog as managed Delta tables.

The Silver service principal only has access to Bronze (SELECT) and
Silver (CREATE TABLE, MODIFY) – it cannot read or write Gold.
"""
import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--bronze-catalog", required=True)
    p.add_argument("--bronze-schema", required=True)
    p.add_argument("--silver-catalog", required=True)
    p.add_argument("--silver-schema", required=True)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`source_raw`"
    target_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`source_refined`"

    df = spark.read.table(source_table)

    # Deduplicate and drop rows with null primary key
    df_clean = (
        df.dropDuplicates()
          .dropna(subset=["id"])
          .withColumn("_refined_at", current_timestamp())
    )

    df_clean.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)

    print(f"[silver] Wrote {df_clean.count()} rows to {target_table}")


if __name__ == "__main__":
    main()
