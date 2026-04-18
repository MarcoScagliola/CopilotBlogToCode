import argparse
from pyspark.sql import SparkSession

def main():
    parser = argparse.ArgumentParser(description="Bronze layer: ingest raw data")
    parser.add_argument("--catalog", required=True, help="Catalog name")
    parser.add_argument("--schema", required=True, help="Schema name")
    parser.add_argument("--storage-account", required=True, help="Storage account name")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("bronze-ingestion").getOrCreate()

    # Example: generate sample raw events
    sample_data = [
        (1, "event_a", "2026-04-18"),
        (2, "event_b", "2026-04-18"),
        (3, "event_c", "2026-04-18"),
    ]
    
    df = spark.createDataFrame(sample_data, ["raw_id", "event_type", "event_date"])
    
    # Write to bronze layer table
    table_name = f"{args.catalog}.{args.schema}.raw_events"
    df.write.mode("overwrite").format("delta").option("mergeSchema", "true").saveAsTable(table_name)
    
    print(f"Bronze ingestion complete: {table_name}")

if __name__ == "__main__":
    main()
