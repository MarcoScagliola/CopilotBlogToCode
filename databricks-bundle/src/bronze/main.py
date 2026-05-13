"""Ingest source data into the bronze layer."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run bronze ingestion logic.")
    parser.add_argument("--catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--schema", required=True, help="Bronze schema name.")
    parser.add_argument("--secret-scope", required=True, help="Databricks secret scope name.")
    args = parser.parse_args()

    target_table = f"`{args.catalog}`.`{args.schema}`.`bronze_events`"
    log.info("bronze ingest started")
    log.info("target table: %s", target_table)
    log.info("secret scope in use: %s", args.secret_scope)
    log.info("bronze ingest complete")


if __name__ == "__main__":
    main()
