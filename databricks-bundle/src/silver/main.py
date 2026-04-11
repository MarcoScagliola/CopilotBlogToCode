import argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    spark = SparkSession.builder.appName("silver-transform").getOrCreate()

    source = f"{args.bronze_catalog}.{args.bronze_schema}.raw_data"
    target = f"{args.silver_catalog}.{args.silver_schema}.clean_data"

    df = spark.table(source)
    result = df.dropDuplicates().withColumn("transform_ts", current_timestamp())
    result.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target)


if __name__ == "__main__":
    main()
