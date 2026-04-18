import argparse
from pyspark.sql import SparkSession


def main() -> None:
    parser = argparse.ArgumentParser(description="Silver layer refinement")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("silver-layer").getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.raw_events"
    target_table = f"{args.target_catalog}.{args.target_schema}.events"

    df = spark.read.table(source_table).dropDuplicates(["raw_id"])
    df.write.mode("overwrite").format("delta").saveAsTable(target_table)

    print(f"Silver write completed: {target_table}")


if __name__ == "__main__":
    main()
