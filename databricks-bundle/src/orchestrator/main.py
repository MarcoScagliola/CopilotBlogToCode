"""
Orchestrator checkpoint – records pipeline run status in Gold catalog.

Writes a single checkpoint row containing the UTC timestamp and run status
to the `pipeline_checkpoint` table in the Gold catalog, enabling
idempotent re-run detection and audit traceability.

Usage (via Databricks job parameters):
  --gold_catalog  Gold Unity Catalog name
  --gold_schema   Gold schema name
"""

import argparse
from datetime import datetime, timezone
from pyspark.sql import SparkSession
from pyspark.sql import Row


def parse_args():
    parser = argparse.ArgumentParser(description="Orchestrator checkpoint job")
    parser.add_argument("--gold_catalog", required=True)
    parser.add_argument("--gold_schema", required=True)
    return parser.parse_args()


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()

    checkpoint_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.pipeline_checkpoint"

    # Attempt to read the Databricks run context if available
    try:
        run_id = spark.conf.get("spark.databricks.job.runId", "unknown")
        job_id = spark.conf.get("spark.databricks.job.id", "unknown")
    except Exception:
        run_id = "unknown"
        job_id = "unknown"

    utc_now = datetime.now(timezone.utc).isoformat()

    checkpoint_row = Row(
        run_timestamp=utc_now,
        run_status="success",
        job_id=job_id,
        run_id=run_id,
    )

    checkpoint_df = spark.createDataFrame([checkpoint_row])

    (
        checkpoint_df.write.format("delta")
        .mode("append")
        .option("mergeSchema", "true")
        .saveAsTable(checkpoint_table)
    )

    print(f"[orchestrator] Checkpoint written to {checkpoint_table} at {utc_now}")


if __name__ == "__main__":
    main()
