import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze layer ingestion entrypoint.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(f"Bronze task scaffold running for {args.catalog}.{args.schema} using scope {args.secret_scope}")


if __name__ == "__main__":
    main()
