import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`source_raw`"
    target = f"`{args.silver_catalog}`.`{args.silver_schema}`.`source_refined`"

    df = spark.read.table(source)
    refined = df.dropDuplicates().dropna(subset=["id"]).withColumn("_refined_at", current_timestamp())

    refined.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(target)


if __name__ == "__main__":
    main()
