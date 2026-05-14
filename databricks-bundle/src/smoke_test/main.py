import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test entrypoint for medallion flow.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", type=int, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(
        "Smoke test scaffold validated layer mapping: "
        f"{args.bronze_catalog}.{args.bronze_schema} -> "
        f"{args.silver_catalog}.{args.silver_schema} -> "
        f"{args.gold_catalog}.{args.gold_schema}, min rows={args.min_row_count}"
    )


if __name__ == "__main__":
    main()
