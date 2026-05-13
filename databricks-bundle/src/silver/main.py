"""Transform bronze datasets into curated silver outputs."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run silver transformation logic.")
    parser.add_argument("--source-catalog", required=True, help="Source catalog name.")
    parser.add_argument("--source-schema", required=True, help="Source schema name.")
    parser.add_argument("--target-catalog", required=True, help="Target catalog name.")
    parser.add_argument("--target-schema", required=True, help="Target schema name.")
    args = parser.parse_args()

    source_table = f"`{args.source_catalog}`.`{args.source_schema}`.`bronze_events`"
    target_table = f"`{args.target_catalog}`.`{args.target_schema}`.`silver_events`"
    log.info("silver transform started")
    log.info("source table: %s", source_table)
    log.info("target table: %s", target_table)
    log.info("silver transform complete")


if __name__ == "__main__":
    main()
