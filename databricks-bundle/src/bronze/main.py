"""
bronze/main.py — Bronze layer ingestion entrypoint.

Ingests raw data from source systems into the Bronze Unity Catalog layer.
Data is stored as append-only Delta managed tables with technical metadata
fields (ingestion timestamp, source system identifier, record hash).

Runs under the Bronze service principal identity with least-privilege access
scoped to the Bronze storage account and Bronze catalog only.
Secrets are read at runtime from the AKV-backed secret scope via
dbutils.secrets.get() — never passed as job parameters or hardcoded.

Arguments are injected by the Databricks job runner via spark_python_task
parameters. See databricks-bundle/resources/jobs.yml for the parameter list.
"""
from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze layer: raw ingestion into Delta managed tables.")
    parser.add_argument("--catalog", required=True, help="Bronze Unity Catalog catalog name.")
    parser.add_argument("--schema", required=True, help="Bronze Unity Catalog schema name.")
    parser.add_argument("--storage-account", required=True, help="Bronze ADLS Gen2 storage account name.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    print(
        f"[bronze] catalog={args.catalog}, schema={args.schema}, "
        f"storage={args.storage_account}, scope={args.secret_scope}"
    )

    # TODO: implement source ingestion.
    # Resolution:
    #   1. Read source credentials from the secret scope at runtime using
    #      dbutils.secrets.get(scope=args.secret_scope, key="<key-name>").
    #      Never log or print secret values.
    #   2. Ingest raw data from the source system into Delta managed tables
    #      under {catalog}.{schema}.
    #   3. Append technical metadata: _ingestion_ts (current_timestamp()),
    #      _source_system (string literal), _row_hash (sha2 of all source cols).
    #   4. Apply Automatic Liquid Clustering (CLUSTER BY AUTO) on new tables
    #      on DBR 15.4 LTS+ — do not use manual partitioning or Z-ordering.
    #   5. Source system type and format: not stated in article. See SPEC.md §
    #      Data model for the outstanding decision.


if __name__ == "__main__":
    main()
