import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze layer ingestion job")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    table_name = f"{args.catalog}.{args.schema}.raw_events"

    # Keep runtime secrets out of logs: retrieve only when needed and never print.
    _ = args.secret_scope

    df = (
        spark.range(1, 101)
        .withColumn("event_time", F.current_timestamp())
        .withColumn("payload", F.concat(F.lit("event-"), F.col("id")))
    )

    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.catalog}.{args.schema}")
    df.write.format("delta").mode("append").saveAsTable(table_name)


if __name__ == "__main__":
    main()
