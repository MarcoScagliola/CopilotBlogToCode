import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold layer aggregation entrypoint.")
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(
        "Running gold job with "
        f"silver={args.silver_catalog}.{args.silver_schema} "
        f"target={args.catalog}.{args.schema} "
        f"storage_account={args.storage_account} secret_scope={args.secret_scope}"
    )

    # TODO: Implement silver-to-gold aggregation logic for analytics-ready outputs.


if __name__ == "__main__":
    main()
