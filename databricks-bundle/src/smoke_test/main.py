import argparse
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test for medallion deployment sanity checks.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    checks = []

    for layer in ["bronze", "silver", "gold"]:
        catalog = getattr(args, f"{layer}_catalog")
        schema = getattr(args, f"{layer}_schema")
        if not catalog or not schema:
            checks.append(f"Missing catalog/schema for {layer}")

    if not args.secret_scope:
        checks.append("Missing secret scope")

    if checks:
        print("Smoke test failed:")
        for check in checks:
            print(f"- {check}")
        sys.exit(1)

    print("Smoke test passed.")
    # TODO: Add Databricks runtime checks for UC objects and required grants.


if __name__ == "__main__":
    main()
