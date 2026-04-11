import argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import count, current_timestamp


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    spark = SparkSession.builder.appName("gold-aggregate").getOrCreate()

    source = f"{args.silver_catalog}.{args.silver_schema}.clean_data"
    target = f"{args.gold_catalog}.{args.gold_schema}.summary_data"

    df = spark.table(source)
    result = df.groupBy("event_type").agg(count("*").alias("event_count")).withColumn("aggregate_ts", current_timestamp())
    result.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target)


if __name__ == "__main__":
    main()
