import argparse
from pyspark.sql import SparkSession

def main():
    parser = argparse.ArgumentParser(description="Silver layer: deduplicate and refine")
    parser.add_argument("--catalog", required=True, help="Catalog name")
    parser.add_argument("--source-schema", required=True, help="Source schema (bronze)")
    parser.add_argument("--target-schema", required=True, help="Target schema (silver)")
    parser.add_argument("--storage-account", required=True, help="Storage account name")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("silver-transform").getOrCreate()

    # Read bronze raw events
    source_table = f"{args.catalog}.{args.source_schema}.raw_events"
    df = spark.read.format("delta").table(source_table)

    # Deduplicate on raw_id
    df_deduplicated = df.dropDuplicates(["raw_id"])

    # Write to silver layer table
    target_table = f"{args.catalog}.{args.target_schema}.events"
    df_deduplicated.write.mode("overwrite").format("delta").option("mergeSchema", "true").saveAsTable(target_table)

    print(f"Silver transformation complete: {target_table}")

if __name__ == "__main__":
    main()
