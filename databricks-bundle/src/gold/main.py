import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold layer curation entrypoint.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(
        "Gold task scaffold running from "
        f"{args.source_catalog}.{args.source_schema} to {args.target_catalog}.{args.target_schema}"
    )


if __name__ == "__main__":
    main()
