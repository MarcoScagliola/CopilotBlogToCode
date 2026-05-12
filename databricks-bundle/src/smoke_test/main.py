from __future__ import annotations

import argparse
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def run_checks() -> list[str]:
    return []


def main() -> int:
    _ = parse_args()
    failures = run_checks()
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print("smoke-ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
