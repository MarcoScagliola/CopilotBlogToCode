"""Setup scaffold for medallion layer resources in Unity Catalog."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _log_layer(layer: str, catalog: str, schema: str, storage_account: str, connector_id: str) -> None:
    log.info(
        "layer=%s catalog=%s schema=%s storage=%s connector=%s",
        layer,
        catalog,
        schema,
        storage_account,
        connector_id,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup medallion UC objects.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--bronze-storage-account", required=True)
    parser.add_argument("--silver-storage-account", required=True)
    parser.add_argument("--gold-storage-account", required=True)
    parser.add_argument("--bronze-access-connector-id", required=True)
    parser.add_argument("--silver-access-connector-id", required=True)
    parser.add_argument("--gold-access-connector-id", required=True)
    args = parser.parse_args()

    log.info("setup start")
    _log_layer("bronze", args.bronze_catalog, args.bronze_schema, args.bronze_storage_account, args.bronze_access_connector_id)
    _log_layer("silver", args.silver_catalog, args.silver_schema, args.silver_storage_account, args.silver_access_connector_id)
    _log_layer("gold", args.gold_catalog, args.gold_schema, args.gold_storage_account, args.gold_access_connector_id)
    log.info("setup complete (scaffold)")


if __name__ == "__main__":
    main()
