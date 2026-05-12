"""
Bronze layer entrypoint — raw ingestion into append-only Delta managed tables.

Reads from source systems and lands data into the Bronze catalog/schema without
transformation.  All writes are append-only to preserve a full audit trail.
"""
import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Bronze layer: raw ingestion into Delta managed tables."
    )
    parser.add_argument("--catalog", required=True, help="Unity Catalog catalog name.")
    parser.add_argument("--schema", required=True, help="Unity Catalog schema name.")
    parser.add_argument(
        "--storage-account",
        required=True,
        help="ADLS Gen2 storage account name backing the Bronze External Location.",
    )
    parser.add_argument(
        "--secret-scope",
        required=True,
        help="Databricks secret scope name (AKV-backed) used for source credentials.",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    print(
        f"[bronze] catalog={args.catalog}, schema={args.schema}, "
        f"storage_account={args.storage_account}, "
        f"secret_scope={args.secret_scope}"
    )

    # TODO: implement source extraction and append-only Delta writes.
    print("[bronze] Bronze stub complete — replace with ingestion logic.")


if __name__ == "__main__":
    main(sys.argv[1:])
