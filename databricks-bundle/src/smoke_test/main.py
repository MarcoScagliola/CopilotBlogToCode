"""Smoke-test scaffold for medallion deployment.

Validates layer namespace parameters are wired and applies a minimal row-count
threshold placeholder.
"""

import argparse
import logging
import sys

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _check_layer(layer: str, catalog: str, schema: str, min_rows: int) -> bool:
    namespace = f"`{catalog}`.`{schema}`"
    log.info("check layer=%s namespace=%s min_rows=%d", layer, namespace, min_rows)
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Run medallion smoke test.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", type=int, default=1)
    args = parser.parse_args()

    ok = [
        _check_layer("bronze", args.bronze_catalog, args.bronze_schema, args.min_row_count),
        _check_layer("silver", args.silver_catalog, args.silver_schema, args.min_row_count),
        _check_layer("gold", args.gold_catalog, args.gold_schema, args.min_row_count),
    ]

    if not all(ok):
        log.error("smoke test failed")
        sys.exit(1)

    log.info("smoke test complete (scaffold)")


if __name__ == "__main__":
    main()
