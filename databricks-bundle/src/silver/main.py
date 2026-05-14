from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Silver layer transformation entrypoint.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    print(
        "silver layer transition "
        f"{args.source_catalog}.{args.source_schema} -> {args.target_catalog}.{args.target_schema}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
