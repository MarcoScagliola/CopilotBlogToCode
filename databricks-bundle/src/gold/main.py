import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args():
    parser = argparse.ArgumentParser(description="Gold curation job")
    parser.add_argument("--input-catalog", required=True)
    parser.add_argument("--input-schema", required=True)
    parser.add_argument("--input-table", required=True)
    parser.add_argument("--output-catalog", required=True)
    parser.add_argument("--output-schema", required=True)
    parser.add_argument("--output-table", required=True)
    return parser.parse_args()


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = f"{args.input_catalog}.{args.input_schema}.{args.input_table}"
    target_table = f"{args.output_catalog}.{args.output_schema}.{args.output_table}"

    df = (
        spark.read.table(source_table)
        .groupBy(F.to_date("_refined_at").alias("event_date"))
        .agg(
            F.count("*").alias("record_count"),
            F.max("_refined_at").alias("last_refined_at"),
        )
        .withColumn("_curated_at", F.current_timestamp())
    )

    df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)


if __name__ == "__main__":
    main()
