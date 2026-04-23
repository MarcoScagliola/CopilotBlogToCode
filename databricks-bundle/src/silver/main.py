"""
Silver layer: refinement / deduplication job.

Reads from the bronze catalog and writes deduplicated events to the silver catalog.
"""

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.window import Window
from pyspark.sql import functions as F

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Silver refinement layer job.")
    parser.add_argument("--source-catalog", required=True, help="Source (bronze) catalog name")
    parser.add_argument("--source-schema", required=True, help="Source (bronze) schema name")
    parser.add_argument("--target-catalog", required=True, help="Target (silver) catalog name")
    parser.add_argument("--target-schema", required=True, help="Target (silver) schema name")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.raw_events"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.events"

    log.info("Silver job started. %s → %s", source_table, target_table)

    df = spark.table(source_table)

    # Deduplication: keep the latest row per event_id
    window = Window.partitionBy("event_id").orderBy(F.desc("ingested_at"))
    df_deduped = (
        df.withColumn("_rn", F.row_number().over(window))
        .filter(F.col("_rn") == 1)
        .drop("_rn")
    )

    (
        df_deduped.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "false")
        .saveAsTable(target_table)
    )
    log.info("Silver job complete. Rows written: %d", df_deduped.count())


if __name__ == "__main__":
    main()
import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver layer refinement job")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    source_table = f"{args.source_catalog}.{args.source_schema}.raw_events"
    target_table = f"{args.target_catalog}.{args.target_schema}.events"

    refined = (
        spark.table(source_table)
        .withColumn("event_date", F.to_date(F.col("event_time")))
        .dropDuplicates(["id"])
    )

    (
        refined.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_table)
    )


if __name__ == "__main__":
    main()
