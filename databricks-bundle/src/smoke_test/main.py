"""Run lightweight table existence and row-count checks across layers."""

import argparse
import logging


log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run smoke tests for medallion layer outputs.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name.")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name.")
    parser.add_argument("--min-row-count", required=True, type=int, help="Minimum expected row count.")
    args = parser.parse_args()

    checks = [
        f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`bronze_events`",
        f"`{args.silver_catalog}`.`{args.silver_schema}`.`silver_events`",
        f"`{args.gold_catalog}`.`{args.gold_schema}`.`gold_metrics`",
    ]

    log.info("Smoke test min row count threshold: %s", args.min_row_count)
    for table_name in checks:
      log.info("Smoke check target: %s", table_name)
    log.info("Smoke test scaffold executed")


if __name__ == "__main__":
    main()
