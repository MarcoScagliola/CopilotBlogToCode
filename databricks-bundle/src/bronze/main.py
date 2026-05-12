"""
Bronze layer entrypoint — bronze-layer job.

Reads from source systems and writes raw data to the Bronze catalog/schema
using managed tables in Unity Catalog. Credentials are read at runtime from
the AKV-backed secret scope — never hardcoded.

TODO: Implement ingestion logic once source systems and formats are confirmed.
      See SPEC.md § Data model (source systems: not stated in article) and
      TODO.md § Post-infrastructure for the runtime-secrets key list.
"""

from __future__ import annotations

import argparse
import sys


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Bronze layer: ingest raw data into the Bronze catalog."
    )
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name for Bronze.")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name for Bronze.")
    parser.add_argument("--storage-account", required=True, help="Storage account name for Bronze.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    print("=== Bronze Layer Configuration ===")
    print(f"  catalog        : {args.catalog}")
    print(f"  schema         : {args.schema}")
    print(f"  storage_account: {args.storage_account}")
    print(f"  secret_scope   : {args.secret_scope}")

    # TODO: read source credentials via dbutils.secrets.get(args.secret_scope, "<key>")
    # TODO: implement ingestion from source systems into args.catalog.args.schema
    print("Bronze ingestion complete (stub).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
