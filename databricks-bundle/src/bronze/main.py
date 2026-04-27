import argparse
from datetime import datetime, timezone

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion layer.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def load_source_secret(secret_scope: str) -> str:
    try:
        return dbutils.secrets.get(secret_scope, "source-system-token")  # type: ignore[name-defined]
    except Exception:
        return ""


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    _ = load_source_secret(args.secret_scope)

    now = datetime.now(timezone.utc).isoformat()
    rows = [
        ("evt-001", "purchase", 42.0, now),
        ("evt-002", "purchase", 99.0, now),
        ("evt-003", "refund", -5.0, now),
    ]
    dataframe = spark.createDataFrame(rows, ["event_id", "event_type", "amount", "event_time_utc"])
    target_table = f"{args.catalog}.{args.schema}.raw_events"

    (
        dataframe.withColumn("ingested_at_utc", F.current_timestamp())
        .write
        .mode("append")
        .saveAsTable(target_table)
    )

    print(f"Bronze write complete: {target_table}")


if __name__ == "__main__":
    main()