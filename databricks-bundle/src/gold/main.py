"""
Gold aggregation layer – aggregates Silver data into summary tables.

Reads from Silver catalog, applies GROUP BY category with SUM of numeric
metrics, and writes the aggregated result to the Gold managed Delta table.

Usage (via Databricks job parameters):
  --silver_catalog    Silver Unity Catalog name
  --silver_schema     Silver schema name
  --gold_catalog      Gold Unity Catalog name
  --gold_schema       Gold schema name
  --source_table_name Source/input table name
"""

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import NumericType


def parse_args():
    parser = argparse.ArgumentParser(description="Gold aggregation job")
    parser.add_argument("--silver_catalog", required=True)
    parser.add_argument("--silver_schema", required=True)
    parser.add_argument("--gold_catalog", required=True)
    parser.add_argument("--gold_schema", required=True)
    parser.add_argument("--source_table_name", required=True)
    return parser.parse_args()


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`{args.source_table_name}`"
    target_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.aggregated"

    silver_df = spark.read.table(source_table)

    # Identify category column (first string-type column) and numeric columns
    string_cols = [f.name for f in silver_df.schema.fields if isinstance(f.dataType, __import__("pyspark.sql.types", fromlist=["StringType"]).StringType)]
    numeric_cols = [f.name for f in silver_df.schema.fields if f.dataType.typeName() in ("integer", "long", "double", "float", "decimal")]

    category_col = string_cols[0] if string_cols else None

    if category_col is None or not numeric_cols:
        # Fallback: write silver as-is with a row count column
        gold_df = silver_df.withColumn("_row_count", F.lit(silver_df.count()))
    else:
        agg_exprs = [F.sum(c).alias(f"sum_{c}") for c in numeric_cols]
        gold_df = silver_df.groupBy(category_col).agg(*agg_exprs)

    (
        gold_df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )

    print(f"[gold] Wrote {gold_df.count()} rows to {target_table}")


if __name__ == "__main__":
    main()
