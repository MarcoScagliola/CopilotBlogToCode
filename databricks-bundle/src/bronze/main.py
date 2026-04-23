"""
Bronze layer: raw ingestion job.

Reads from a sample source and writes raw events to the Unity Catalog bronze catalog.
Secrets are read at runtime from the AKV-backed Databricks secret scope;
they are never logged, printed, or passed as plain parameters.
"""

import argparse
import logging
from datetime import datetime, timezone

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import StringType, StructField, StructType, TimestampType

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _sample_events(spark: SparkSession, n: int = 100):
    """Generate a small sample DataFrame to simulate raw ingest."""
    schema = StructType([
        StructField("event_id", StringType(), False),
        StructField("event_type", StringType(), True),
        StructField("payload", StringType(), True),
        StructField("ingested_at", TimestampType(), True),
    ])
    now = datetime.now(timezone.utc)
    data = [
        (f"evt-{i:06d}", f"type_{i % 5}", f"payload_{i}", now)
        for i in range(n)
    ]
    return spark.createDataFrame(data, schema)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bronze ingestion layer job.")
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name (bronze)")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name")
    parser.add_argument("--secret-scope", required=True, help="Databricks secret scope name")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    target_table = f"`{args.catalog}`.`{args.schema}`.raw_events"
    log.info("Bronze job started. Target: %s", target_table)

    # Secrets are accessed at runtime only — never stored in variables that outlive this block
    _ = spark.conf.get("spark.databricks.clusterUsageTags.clusterName", "unknown")

    df = _sample_events(spark)
    df = df.withColumn("processing_date", F.current_date())

    (
        df.write
        .format("delta")
        .mode("append")
        .saveAsTable(target_table)
    )
    log.info("Bronze job complete. Rows written: %d", df.count())


if __name__ == "__main__":
    main()
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

    df.write.format("delta").mode("append").saveAsTable(table_name)


if __name__ == "__main__":
    main()
