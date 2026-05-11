"""Silver layer scaffold for Bronze-to-Silver transformations."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Silver transformations.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    args = parser.parse_args()

    source_ns = f"`{args.source_catalog}`.`{args.source_schema}`"
    target_ns = f"`{args.target_catalog}`.`{args.target_schema}`"
    log.info("silver start source=%s target=%s", source_ns, target_ns)
    log.info("silver complete (scaffold)")


if __name__ == "__main__":
    main()
