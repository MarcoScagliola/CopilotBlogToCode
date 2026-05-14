#!/usr/bin/env python3
from __future__ import annotations

import argparse


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Silver layer placeholder")
    p.add_argument("--source-catalog", required=True)
    p.add_argument("--source-schema", required=True)
    p.add_argument("--target-catalog", required=True)
    p.add_argument("--target-schema", required=True)
    return p


def main() -> int:
    args = parser().parse_args()
    print("Silver placeholder executed")
    print(
        f"Flow: {args.source_catalog}.{args.source_schema} -> "
        f"{args.target_catalog}.{args.target_schema}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
