"""Produce Gold-layer curated datasets from Silver refined data."""

import argparse
import logging


log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Execute Gold curation stage.")
    parser.add_argument("--source-catalog", required=True, help="Source Silver catalog.")
    parser.add_argument("--source-schema", required=True, help="Source Silver schema.")
    parser.add_argument("--target-catalog", required=True, help="Target Gold catalog.")
    parser.add_argument("--target-schema", required=True, help="Target Gold schema.")
    args = parser.parse_args()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`silver_events`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`gold_metrics`"
    log.info("Gold source table: %s", source_table)
    log.info("Gold target table: %s", target_table)
    log.info("Gold stage scaffold executed")


if __name__ == "__main__":
    main()
