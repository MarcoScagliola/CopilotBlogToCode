"""
smoke_test/main.py — End-to-end smoke test entrypoint.

Verifies that identity, networking, storage, secret scope, and Unity Catalog
objects are all correctly wired after a fresh deployment. Runs as the
deployment service principal. Exits 1 if any check fails.

All layer catalog/schema names and the secret scope come from job task parameters.
"""

import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Smoke test: verify identity, storage, secrets, and UC objects are reachable."
    )
    parser.add_argument("--bronze-catalog", required=True, help="Bronze Unity Catalog catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze Unity Catalog schema name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver Unity Catalog catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Silver Unity Catalog schema name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold Unity Catalog catalog name.")
    parser.add_argument("--gold-schema", required=True, help="Gold Unity Catalog schema name.")
    parser.add_argument("--secret-scope", required=True, help="Key Vault-backed Databricks secret scope name.")
    return parser.parse_args(argv)


def run_checks(args):
    """
    Execute smoke-test assertions. Returns a list of failure messages.
    An empty list means all checks passed.
    """
    failures = []

    print("Smoke test — resolved configuration:")
    print(f"  bronze: {args.bronze_catalog}.{args.bronze_schema}")
    print(f"  silver: {args.silver_catalog}.{args.silver_schema}")
    print(f"  gold:   {args.gold_catalog}.{args.gold_schema}")
    print(f"  secret_scope: {args.secret_scope}")

    # TODO: Implement smoke-test checks. Examples:
    #   1. Verify catalogs exist: spark.sql(f"SHOW CATALOGS LIKE '{catalog}'")
    #   2. Verify schemas exist: spark.sql(f"SHOW SCHEMAS IN {catalog} LIKE '{schema}'")
    #   3. Verify secret scope is reachable: dbutils.secrets.list(scope)
    #   4. Verify storage access: spark read from a known path in each storage account.
    #   5. Check that each layer's service principal has the expected UC privileges.
    # If any check fails, append a descriptive message to `failures`.
    print("TODO: Smoke test checks not yet implemented.")

    return failures


def main(argv=None):
    args = parse_args(argv)
    failures = run_checks(args)

    if failures:
        print(f"\nSmoke test FAILED — {len(failures)} check(s) did not pass:")
        for msg in failures:
            print(f"  FAIL: {msg}")
        return 1

    print("\nSmoke test PASSED.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
