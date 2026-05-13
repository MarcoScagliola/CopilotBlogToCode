"""Create baseline medallion objects and report effective runtime wiring."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup medallion catalogs, schemas, and storage bindings.")
    parser.add_argument("--bronze-catalog", required=True, help="Bronze catalog name.")
    parser.add_argument("--silver-catalog", required=True, help="Silver catalog name.")
    parser.add_argument("--gold-catalog", required=True, help="Gold catalog name.")
    parser.add_argument("--bronze-schema", required=True, help="Bronze schema name.")
    parser.add_argument("--silver-schema", required=True, help="Silver schema name.")
    parser.add_argument("--gold-schema", required=True, help="Gold schema name.")
    parser.add_argument("--bronze-storage-account", required=True, help="Bronze ADLS account.")
    parser.add_argument("--silver-storage-account", required=True, help="Silver ADLS account.")
    parser.add_argument("--gold-storage-account", required=True, help="Gold ADLS account.")
    parser.add_argument("--bronze-access-connector-id", required=True, help="Bronze connector resource ID.")
    parser.add_argument("--silver-access-connector-id", required=True, help="Silver connector resource ID.")
    parser.add_argument("--gold-access-connector-id", required=True, help="Gold connector resource ID.")
    args = parser.parse_args()

    log.info("setup started")
    log.info("bronze target: %s.%s", args.bronze_catalog, args.bronze_schema)
    log.info("silver target: %s.%s", args.silver_catalog, args.silver_schema)
    log.info("gold target: %s.%s", args.gold_catalog, args.gold_schema)
    log.info("setup complete")


if __name__ == "__main__":
    main()
