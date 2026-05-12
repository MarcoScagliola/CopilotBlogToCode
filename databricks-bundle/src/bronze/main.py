import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze layer ingestion entrypoint.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(
        f"Running bronze job with catalog={args.catalog} "
        f"schema={args.schema} storage_account={args.storage_account} secret_scope={args.secret_scope}"
    )

    # TODO: Implement source extraction and raw-to-bronze ingestion logic.


if __name__ == "__main__":
    main()
