from __future__ import annotations

import argparse
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    print("bronze", args.catalog, args.schema)
    return 0


if __name__ == "__main__":
    sys.exit(main())
