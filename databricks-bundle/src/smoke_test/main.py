from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Smoke-test entrypoint for medallion flow.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", type=int, required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    print("smoke test arguments validated")
    print(f"min_row_count={args.min_row_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
