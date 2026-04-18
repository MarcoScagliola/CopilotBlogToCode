import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

def main():
    parser = argparse.ArgumentParser(description="Gold layer: aggregate and summarize")
    parser.add_argument("--catalog", required=True, help="Catalog name")
    parser.add_argument("--source-schema", required=True, help="Source schema (silver)")
    parser.add_argument("--target-schema", required=True, help="Target schema (gold)")
    parser.add_argument("--storage-account", required=True, help="Storage account name")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("gold-aggregate").getOrCreate()

    # Read silver events
    source_table = f"{args.catalog}.{args.source_schema}.events"
    df = spark.read.format("delta").table(source_table)

    # Aggregate: count events by type
    df_agg = df.groupBy("event_type").agg(F.count("raw_id").alias("event_count"))

    # Write to gold layer table
    target_table = f"{args.catalog}.{args.target_schema}.event_summary"
    df_agg.write.mode("overwrite").format("delta").option("mergeSchema", "true").saveAsTable(target_table)

    print(f"Gold aggregation complete: {target_table}")

if __name__ == "__main__":
    main()
