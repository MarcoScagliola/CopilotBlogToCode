"""
Gold layer: aggregation / serving job.

Reads from the silver catalog and writes an aggregated summary to the gold catalog.
"""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Gold aggregation layer job.")
    parser.add_argument("--source-catalog", required=True, help="Source (silver) catalog name")
    parser.add_argument("--source-schema", required=True, help="Source (silver) schema name")
    parser.add_argument("--target-catalog", required=True, help="Target (gold) catalog name")
    parser.add_argument("--target-schema", required=True, help="Target (gold) schema name")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.events"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.event_summary"

    log.info("Gold job started. %s → %s", source_table, target_table)

    df = spark.table(source_table)

    df_summary = (
        df.groupBy("event_type", F.to_date("ingested_at").alias("event_date"))
        .agg(
            F.count("event_id").alias("event_count"),
            F.max("ingested_at").alias("latest_event_at"),
        )
    )

    (
        df_summary.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "false")
        .saveAsTable(target_table)
    )
    log.info("Gold job complete. Rows written: %d", df_summary.count())


if __name__ == "__main__":
    main()
import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold layer curation job")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.events"
    target_table = f"{args.target_catalog}.{args.target_schema}.event_summary"

    summary = (
        spark.table(source_table)
        .groupBy("event_date")
        .agg(F.count("*").alias("event_count"))
        .orderBy(F.col("event_date").desc())
    )

    (
        summary.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )


if __name__ == "__main__":
    main()
