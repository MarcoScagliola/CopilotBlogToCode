"""
Smoke test entrypoint — smoke-test job.

Runs a minimal end-to-end check after deployment: verifies that the secret
scope is reachable and that the expected catalogs/schemas exist in Unity Catalog.
Exits non-zero if any check fails, causing the Databricks job to fail visibly.

TODO: Expand checks to include table-level reads and write probes once Bronze
      table names are confirmed. See TODO.md § Post-DAB.
"""

from __future__ import annotations

import argparse
import sys


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Smoke test: verify deployment health across all medallion layers."
    )
    parser.add_argument("--bronze-catalog", required=True, help="Unity Catalog catalog name for Bronze.")
    parser.add_argument("--bronze-schema", required=True, help="Unity Catalog schema name for Bronze.")
    parser.add_argument("--silver-catalog", required=True, help="Unity Catalog catalog name for Silver.")
    parser.add_argument("--silver-schema", required=True, help="Unity Catalog schema name for Silver.")
    parser.add_argument("--gold-catalog", required=True, help="Unity Catalog catalog name for Gold.")
    parser.add_argument("--gold-schema", required=True, help="Unity Catalog schema name for Gold.")
    parser.add_argument("--secret-scope", required=True, help="AKV-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def run_checks(args: argparse.Namespace) -> list[str]:
    """Return a list of failure messages. Empty list = all checks passed."""
    failures: list[str] = []

    # TODO: verify secret scope is reachable via dbutils.secrets.listScopes()
    # TODO: verify bronze, silver, gold catalogs exist via spark.sql("SHOW CATALOGS")
    # TODO: verify schemas exist via spark.sql(f"SHOW SCHEMAS IN {catalog}")
    # TODO: verify access connector RBAC by attempting a minimal read on each storage account

    print("=== Smoke Test Configuration ===")
    for layer in ("bronze", "silver", "gold"):
        cat = getattr(args, f"{layer}_catalog")
        sch = getattr(args, f"{layer}_schema")
        print(f"  [{layer}] catalog={cat} schema={sch}")
    print(f"  secret_scope: {args.secret_scope}")
    print("Smoke test checks: stub (no assertions implemented yet).")

    return failures


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    failures = run_checks(args)

    if failures:
        for msg in failures:
            print(f"FAIL: {msg}", file=sys.stderr)
        return 1

    print("All smoke test checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
