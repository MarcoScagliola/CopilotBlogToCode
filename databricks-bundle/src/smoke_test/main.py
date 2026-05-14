"""Verify that bronze, silver, and gold targets exist and contain rows after orchestration completes."""

from __future__ import annotations

import argparse
import logging


LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test medallion tables after orchestration.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze Unity Catalog catalog.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze Unity Catalog schema.")
    parser.add_argument("--silver-catalog", required=True, help="Silver Unity Catalog catalog.")
    parser.add_argument("--silver-schema", required=True, help="Silver Unity Catalog schema.")
    parser.add_argument("--gold-catalog", required=True, help="Gold Unity Catalog catalog.")
    parser.add_argument("--gold-schema", required=True, help="Gold Unity Catalog schema.")
    parser.add_argument("--min-row-count", type=int, default=1, help="Minimum rows expected in bronze and silver tables.")
    return parser.parse_args()


def _assert_rows(table_name: str, minimum_rows: int) -> None:
    row_count = spark.table(table_name).count()
    if row_count < minimum_rows:
        raise RuntimeError(f"Smoke test failed for {table_name}: expected >= {minimum_rows}, got {row_count}")
    LOG.info("Validated %s with %s rows", table_name, row_count)


def main() -> None:
    args = _parse_args()

    bronze_table = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`orders_bronze`"
    silver_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`orders_silver`"
    gold_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.`orders_gold_metrics`"

    _assert_rows(bronze_table, args.min_row_count)
    _assert_rows(silver_table, args.min_row_count)
    _assert_rows(gold_table, 1)
    LOG.info("Smoke test completed successfully.")


if __name__ == "__main__":
    main()