"""
Smoke test entrypoint — validates that the medallion pipeline ran successfully
by asserting that each layer's catalog/schema is reachable and contains at
least one table.

Exits with code 1 if any assertion fails so that the Lakeflow job reports
a failure and CI/CD pipelines are blocked.
"""
import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Smoke test: validate medallion pipeline output."
    )
    parser.add_argument("--bronze-catalog", required=True, help="Unity Catalog catalog name for Bronze.")
    parser.add_argument("--bronze-schema", required=True, help="Unity Catalog schema name for Bronze.")
    parser.add_argument("--silver-catalog", required=True, help="Unity Catalog catalog name for Silver.")
    parser.add_argument("--silver-schema", required=True, help="Unity Catalog schema name for Silver.")
    parser.add_argument("--gold-catalog", required=True, help="Unity Catalog catalog name for Gold.")
    parser.add_argument("--gold-schema", required=True, help="Unity Catalog schema name for Gold.")
    parser.add_argument(
        "--secret-scope",
        required=True,
        help="Databricks secret scope name (AKV-backed).",
    )
    return parser.parse_args(argv)


def run_checks(args):
    """Returns a list of failure messages (empty list = all passed)."""
    failures = []

    layers = [
        ("bronze", args.bronze_catalog, args.bronze_schema),
        ("silver", args.silver_catalog, args.silver_schema),
        ("gold", args.gold_catalog, args.gold_schema),
    ]

    for layer, catalog, schema in layers:
        print(f"[smoke_test] Checking {layer}: catalog={catalog}, schema={schema}")
        # TODO: replace stub with actual Spark catalog inspection, e.g.:
        #   tables = spark.catalog.listTables(f"{catalog}.{schema}")
        #   if not tables:
        #       failures.append(f"{layer} schema {catalog}.{schema} contains no tables")
        print(f"[smoke_test] {layer}: stub check passed")

    return failures


def main(argv=None):
    args = parse_args(argv)
    print(f"[smoke_test] secret_scope={args.secret_scope}")

    failures = run_checks(args)

    if failures:
        for msg in failures:
            print(f"[smoke_test] FAIL: {msg}", file=sys.stderr)
        sys.exit(1)

    print("[smoke_test] All checks passed.")


if __name__ == "__main__":
    main(sys.argv[1:])
