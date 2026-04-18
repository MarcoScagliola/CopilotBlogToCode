import argparse
from pyspark.sql import SparkSession


def main() -> None:
    parser = argparse.ArgumentParser(description="Bronze layer ingestion")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("bronze-layer").getOrCreate()

    data = [
        (1, "event_a", "2026-04-18"),
        (2, "event_b", "2026-04-18"),
        (3, "event_c", "2026-04-18"),
    ]
    df = spark.createDataFrame(data, ["raw_id", "event_type", "event_date"])

    table = f"{args.catalog}.{args.schema}.raw_events"
    df.write.mode("overwrite").format("delta").saveAsTable(table)

    print(f"Bronze write completed: {table}")


if __name__ == "__main__":
    main()
