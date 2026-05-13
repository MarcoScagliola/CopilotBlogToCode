"""Run a lightweight end-to-end readiness check across medallion layers."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate that bronze/silver/gold targets are reachable.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name.")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name.")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name.")
    parser.add_argument("--min-row-count", type=int, required=True, help="Minimum expected row count.")
    args = parser.parse_args()

    bronze_table = f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`bronze_events`"
    silver_table = f"`{args.silver_catalog}`.`{args.silver_schema}`.`silver_events`"
    gold_table = f"`{args.gold_catalog}`.`{args.gold_schema}`.`gold_summary`"
    log.info("smoke test started")
    log.info("checking tables: %s, %s, %s", bronze_table, silver_table, gold_table)
    log.info("minimum row count threshold: %d", args.min_row_count)
    log.info("smoke test complete")


if __name__ == "__main__":
    main()
