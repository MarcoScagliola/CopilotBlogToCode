"""
gold/main.py — Gold layer aggregation entrypoint.

Reads Delta managed tables from the Silver catalog and produces curated,
analytics-ready datasets (dimensional model or semantic layer) in the Gold
Unity Catalog layer for BI, dashboards, and APIs.

Runs under the Gold service principal identity with least-privilege access
scoped to the Gold catalog and storage account. Has read access on Silver;
write access only on Gold. Secrets read at runtime from the AKV-backed scope.

Arguments are injected by the Databricks job runner via spark_python_task
parameters. See databricks-bundle/resources/jobs.yml for the parameter list.
"""
from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold layer: aggregate Silver data into curated analytics datasets.")
    parser.add_argument("--silver-catalog", required=True, help="Source Silver Unity Catalog catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Source Silver Unity Catalog schema name.")
    parser.add_argument("--catalog", required=True, help="Target Gold Unity Catalog catalog name.")
    parser.add_argument("--schema", required=True, help="Target Gold Unity Catalog schema name.")
    parser.add_argument("--storage-account", required=True, help="Gold ADLS Gen2 storage account name.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    print(
        f"[gold] source={args.silver_catalog}.{args.silver_schema}, "
        f"target={args.catalog}.{args.schema}, "
        f"storage={args.storage_account}, scope={args.secret_scope}"
    )

    # TODO: implement Gold aggregation logic.
    # Resolution:
    #   1. Read from {silver_catalog}.{silver_schema} using the Gold SP identity
    #      (Browse + Read File on Silver External Location).
    #   2. Produce dimensional model: fact tables, dimension tables, or semantic
    #      aggregates. Target table names not stated in article — see SPEC.md §
    #      Data model.
    #   3. Optimise for BI read patterns: wide denormalised tables, pre-aggregated
    #      metrics. Gold cluster: compute-optimised, Photon optional (disabled
    #      by default for most workloads per article guidance).
    #   4. Write to {catalog}.{schema} Delta managed tables. Use MERGE INTO or
    #      CREATE OR REPLACE TABLE depending on refresh strategy.
    #   5. Liquid Clustering: CLUSTER BY AUTO on new tables (DBR 15.4 LTS+).
    #   6. A semantic layer may sit on top (not in scope of this entrypoint).


if __name__ == "__main__":
    main()
