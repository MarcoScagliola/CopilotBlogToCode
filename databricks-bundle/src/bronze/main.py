import argparse
from datetime import datetime
from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest seed data into Bronze")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def read_runtime_secret(scope: str, key: str) -> str:
    # Keep secret retrieval at runtime only; never persist or print values.
    return dbutils.secrets.get(scope=scope, key=key)  # type: ignore[name-defined]


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-bronze").getOrCreate()

    _ = read_runtime_secret(args.secret_scope, "source-system-token")

    now = datetime.utcnow().isoformat()
    rows = [
        ("evt-1", "click", "user-a", now),
        ("evt-2", "view", "user-b", now),
        ("evt-3", "click", "user-a", now),
    ]
    df = spark.createDataFrame(rows, ["event_id", "event_type", "user_id", "event_ts"])

    target = f"`{args.catalog}`.`{args.schema}`.`events_bronze`"
    spark.sql(f"CREATE TABLE IF NOT EXISTS {target} (event_id STRING, event_type STRING, user_id STRING, event_ts STRING)")
    df.write.mode("append").saveAsTable(f"{args.catalog}.{args.schema}.events_bronze")

    spark.stop()


if __name__ == "__main__":
    main()
