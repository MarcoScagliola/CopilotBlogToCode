"""Land sample raw events into the Bronze layer using a runtime secret lookup."""

import argparse
import logging

from pyspark.sql import Row, SparkSession
from pyspark.sql.functions import current_timestamp, lit

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingest sample raw events into the Bronze layer.")
    parser.add_argument("--catalog", required=True, help="Target Bronze catalog")
    parser.add_argument("--schema", required=True, help="Target Bronze schema")
    parser.add_argument("--secret-scope", required=True, help="Secret scope used for source-system credentials")
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()
    dbutils = globals().get("dbutils")
    if dbutils is None:
        raise RuntimeError("dbutils is required when this job runs inside Databricks")

    _ = dbutils.secrets.get(scope=args.secret_scope, key="source-system-token")

    target_table = f"`{args.catalog}`.`{args.schema}`.`raw_events`"
    rows = [
        Row(event_id="evt-001", event_type="create", source_system="crm", amount=125.0),
        Row(event_id="evt-002", event_type="update", source_system="crm", amount=80.0),
        Row(event_id="evt-003", event_type="create", source_system="erp", amount=215.5),
    ]

    df = (
        spark.createDataFrame(rows)
        .withColumn("ingested_at", current_timestamp())
        .withColumn("pipeline_layer", lit("bronze"))
    )

    log.info("Writing Bronze events to %s", target_table)
    df.write.mode("overwrite").saveAsTable(target_table)
    log.info("Bronze load complete with %s rows", df.count())


if __name__ == "__main__":
    main()