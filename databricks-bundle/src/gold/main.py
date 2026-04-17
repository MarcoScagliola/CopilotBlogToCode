"""
Gold Layer – Aggregation / Curation
Reads from the Silver catalog, produces consumption-ready aggregates, and
writes to the Gold Unity Catalog as managed Delta tables.

The Gold service principal only has SELECT on Silver and full access on Gold.
It cannot write back to Bronze or Silver, preventing accidental overwrites.
"""
import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, current_timestamp, max as spark_max


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--silver-catalog", required=True)
    p.add_argument("--silver-schema", required=True)
    p.add_argument("--gold-catalog", required=True)
    p.add_argument("--gold-schema", required=True)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`source_refined`"
    target_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.`source_daily_summary`"

    df = spark.read.table(source_table)

    df_agg = (
        df.groupBy(col("event_date"))
          .agg(
              count("*").alias("record_count"),
              spark_max("_refined_at").alias("last_refined_at"),
          )
          .withColumn("_curated_at", current_timestamp())
    )

    df_agg.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)

    print(f"[gold] Wrote {df_agg.count()} summary rows to {target_table}")


if __name__ == "__main__":
    main()
