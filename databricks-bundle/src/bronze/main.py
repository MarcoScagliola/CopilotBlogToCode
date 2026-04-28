"""Ingest seed events into the Bronze layer using runtime-only secret access."""

import argparse
import logging
from datetime import UTC, datetime

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _read_runtime_secret(scope: str, key: str) -> str:
    return dbutils.secrets.get(scope=scope, key=key)  # type: ignore[name-defined]


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingest seed Bronze events")
    parser.add_argument("--catalog", required=True, help="Bronze catalog name")
    parser.add_argument("--schema", required=True, help="Bronze schema name")
    parser.add_argument("--secret-scope", required=True, help="Key Vault-backed Databricks secret scope")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("secure-medallion-bronze").getOrCreate()
    _read_runtime_secret(args.secret_scope, "source-system-token")

    event_ts = datetime.now(UTC).isoformat()
    rows = [
        ("evt-001", "click", "user-a", event_ts),
        ("evt-002", "view", "user-b", event_ts),
        ("evt-003", "purchase", "user-a", event_ts),
    ]
    df = spark.createDataFrame(rows, ["event_id", "event_type", "user_id", "event_ts"])

    target_table = f"{args.catalog}.{args.schema}.events_bronze"
    log.info("Writing Bronze data to %s", target_table)
    df.write.mode("append").saveAsTable(target_table)

    spark.stop()
    log.info("Bronze ingestion complete")


if __name__ == "__main__":
    main()
