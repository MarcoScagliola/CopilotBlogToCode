from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Bronze layer ingestion entrypoint.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    print(f"bronze layer target={args.catalog}.{args.schema}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
