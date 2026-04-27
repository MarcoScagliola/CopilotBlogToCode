"""Silver transformation entrypoint."""

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import Window
from pyspark.sql import functions as F


def main() -> None:
    parser = argparse.ArgumentParser(description="Silver transformation layer.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    source_table = f"{args.source_catalog}.{args.source_schema}.raw_events"
    target_table = f"{args.target_catalog}.{args.target_schema}.events"

    window_spec = Window.partitionBy("event_id").orderBy(F.col("ingested_at_utc").desc())
    refined = (
        spark.table(source_table)
        .withColumn("row_num", F.row_number().over(window_spec))
        .filter(F.col("row_num") == 1)
        .drop("row_num")
    )

    refined.write.mode("overwrite").saveAsTable(target_table)
    print(f"Silver write complete: {target_table}")


if __name__ == "__main__":
    main()