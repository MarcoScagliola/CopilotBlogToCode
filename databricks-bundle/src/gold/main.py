import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def main() -> None:
    parser = argparse.ArgumentParser(description="Gold layer curation")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("gold-layer").getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.events"
    target_table = f"{args.target_catalog}.{args.target_schema}.event_summary"

    df = spark.read.table(source_table)
    summary = df.groupBy("event_type").agg(F.count("raw_id").alias("event_count"))
    summary.write.mode("overwrite").format("delta").saveAsTable(target_table)

    print(f"Gold write completed: {target_table}")


if __name__ == "__main__":
    main()
