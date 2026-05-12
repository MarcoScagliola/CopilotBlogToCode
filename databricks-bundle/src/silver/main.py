import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Silver layer transformation entrypoint.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(
        "Running silver job with "
        f"bronze={args.bronze_catalog}.{args.bronze_schema} "
        f"target={args.catalog}.{args.schema} "
        f"storage_account={args.storage_account} secret_scope={args.secret_scope}"
    )

    # TODO: Implement bronze-to-silver cleansing and conformance transformations.


if __name__ == "__main__":
    main()
