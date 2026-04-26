"""Ingest sample raw events into Bronze table."""

import argparse
import logging
from typing import Any

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _quote(identifier: str) -> str:
    return f"`{identifier}`"


def _try_get_secret(scope: str, key: str) -> None:
    try:
        dbutils: Any = globals().get("dbutils")
        if dbutils is None:
            return
        _ = dbutils.secrets.get(scope=scope, key=key)
        log.info("Validated runtime secret access for scope '%s' and key '%s'.", scope, key)
    except Exception:
        log.warning("Secret lookup skipped or unavailable for scope '%s' and key '%s'.", scope, key)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bronze ingestion job.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("medallion-bronze").getOrCreate()
    target_table = f"{_quote(args.catalog)}.{_quote(args.schema)}.{_quote('raw_events')}"

    _try_get_secret(args.secret_scope, "source-api-token")

    rows = [
        ("evt-1", "purchase", 10.0),
        ("evt-2", "view", 1.0),
        ("evt-3", "purchase", 5.0),
    ]
    df = spark.createDataFrame(rows, ["event_id", "event_type", "amount"])

    df.write.mode("append").option("mergeSchema", "true").saveAsTable(target_table)
    log.info("Bronze load complete: wrote %s rows to %s", df.count(), target_table)


if __name__ == "__main__":
    main()
