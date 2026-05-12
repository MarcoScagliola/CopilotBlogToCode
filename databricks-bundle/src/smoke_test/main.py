"""
smoke_test/main.py — Post-deploy smoke test entrypoint.

Verifies that the deployed Medallion pipeline is correctly wired by performing
lightweight, non-destructive assertions against the Unity Catalog objects and
the Databricks workspace configuration provisioned by the setup job and the
layer entrypoints.

Run this job manually after the first full pipeline execution, and as a
post-deploy gate in CI after `databricks bundle deploy` completes.

Arguments are injected by the Databricks job runner via spark_python_task
parameters. See databricks-bundle/resources/jobs.yml for the parameter list.
"""
from __future__ import annotations

import argparse
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test: assert Medallion objects exist and are accessible.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    failures: list[str] = []

    checks = [
        ("bronze catalog exists", args.bronze_catalog),
        ("silver catalog exists", args.silver_catalog),
        ("gold catalog exists", args.gold_catalog),
    ]

    # TODO: implement Unity Catalog existence checks using spark.sql().
    # Resolution for each check below:
    #   1. Run `SHOW CATALOGS` or `DESCRIBE CATALOG <name>` via spark.sql().
    #      If the catalog does not exist, append a failure message.
    #   2. Run `SHOW SCHEMAS IN <catalog>` to verify the schema exists.
    #   3. Attempt `dbutils.secrets.get(scope=args.secret_scope, key="<key>")`.
    #      If it raises an exception, the secret scope is not wired or the SP
    #      lacks Key Vault access. Record the failure.
    #   4. Exit with sys.exit(1) if any failure was recorded so the Databricks
    #      job marks the run as failed.

    for description, _ in checks:
        print(f"[smoke_test] CHECK: {description} — not yet implemented")

    if failures:
        for msg in failures:
            print(f"[smoke_test] FAIL: {msg}", file=sys.stderr)
        sys.exit(1)

    print("[smoke_test] All checks passed (stub — implement assertions before using as a real gate).")


if __name__ == "__main__":
    main()
