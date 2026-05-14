from __future__ import annotations

import argparse
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion task.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    bronze_table = f"{args.catalog}.{args.schema}.events_bronze"

    # Seed a deterministic Bronze dataset so smoke tests can run in empty environments.
    rows = [
        (1, "sensor-a", "2026-01-01T00:00:00Z", 10.0),
        (2, "sensor-b", "2026-01-01T00:05:00Z", 22.5),
        (3, "sensor-a", "2026-01-01T00:10:00Z", 14.2),
    ]
    df = spark.createDataFrame(rows, ["event_id", "device_id", "event_ts", "reading"])

    spark.sql(f"CREATE CATALOG IF NOT EXISTS {args.catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.catalog}.{args.schema}")

    df.write.format("delta").mode("append").saveAsTable(bronze_table)


if __name__ == "__main__":
    main()
