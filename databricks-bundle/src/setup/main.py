"""
Setup job: idempotently creates Unity Catalog objects for each layer.

Creates per layer:
  1. Storage credential (backed by Access Connector SAMI)
  2. External location (ABFSS on layer storage account)
  3. Catalog (with MANAGED LOCATION pointing to the external location)
  4. Schema

All operations use IF NOT EXISTS patterns so the job is safe to re-run.
"""

import argparse
import logging
from databricks.sdk import WorkspaceClient
from databricks.sdk.service import catalog as dbc

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _create_storage_credential(
    w: WorkspaceClient,
    name: str,
    access_connector_id: str,
) -> None:
    """Create a storage credential backed by an Access Connector (SAMI) if it does not exist."""
    try:
        w.storage_credentials.get(name)
        log.info("Storage credential '%s' already exists — skipping.", name)
        return
    except Exception:
        pass  # does not exist; proceed

    w.storage_credentials.create(
        name=name,
        azure_managed_identity=dbc.AzureManagedIdentity(
            access_connector_id=access_connector_id,
        ),
    )
    log.info("Created storage credential '%s'.", name)


def _create_external_location(
    w: WorkspaceClient,
    name: str,
    url: str,
    credential_name: str,
) -> None:
    """Create an external location if it does not exist."""
    try:
        w.external_locations.get(name)
        log.info("External location '%s' already exists — skipping.", name)
        return
    except Exception:
        pass

    w.external_locations.create(
        name=name,
        url=url,
        credential_name=credential_name,
    )
    log.info("Created external location '%s' → %s.", name, url)


def _create_catalog(
    w: WorkspaceClient,
    catalog_name: str,
    storage_location: str,
) -> None:
    """Create a Unity Catalog catalog with a managed location if it does not exist."""
    try:
        w.catalogs.get(catalog_name)
        log.info("Catalog '%s' already exists — skipping.", catalog_name)
        return
    except Exception:
        pass

    w.catalogs.create(
        name=catalog_name,
        storage_root=storage_location,
    )
    log.info("Created catalog '%s' with managed location '%s'.", catalog_name, storage_location)


def _create_schema(w: WorkspaceClient, catalog_name: str, schema_name: str) -> None:
    """Create a UC schema if it does not exist."""
    full_name = f"{catalog_name}.{schema_name}"
    try:
        w.schemas.get(full_name)
        log.info("Schema '%s' already exists — skipping.", full_name)
        return
    except Exception:
        pass

    w.schemas.create(name=schema_name, catalog_name=catalog_name)
    log.info("Created schema '%s'.", full_name)


def setup_layer(
    w: WorkspaceClient,
    layer: str,
    catalog_name: str,
    schema_name: str,
    storage_account_name: str,
    access_connector_id: str,
    container_name: str | None = None,
) -> None:
    container = container_name or layer
    abfss_url = f"abfss://{container}@{storage_account_name}.dfs.core.windows.net/"
    credential_name = f"sc-{layer}-{storage_account_name}"
    ext_loc_name = f"el-{layer}-{storage_account_name}"

    log.info("--- Setting up layer: %s ---", layer)
    _create_storage_credential(w, credential_name, access_connector_id)
    _create_external_location(w, ext_loc_name, abfss_url, credential_name)
    _create_catalog(w, catalog_name, abfss_url)
    _create_schema(w, catalog_name, schema_name)


def main() -> None:
    parser = argparse.ArgumentParser(description="Idempotent Unity Catalog setup for all layers.")

    for layer in ("bronze", "silver", "gold"):
        parser.add_argument(f"--{layer}-catalog", required=True, help=f"UC catalog name for {layer}")
        parser.add_argument(f"--{layer}-schema", required=True, help=f"UC schema name for {layer}")
        parser.add_argument(f"--{layer}-storage-account", required=True, help=f"ADLS storage account name for {layer}")
        parser.add_argument(f"--{layer}-access-connector-id", required=True, help=f"Azure resource ID of Access Connector for {layer}")

    args = parser.parse_args()
    w = WorkspaceClient()

    for layer in ("bronze", "silver", "gold"):
        setup_layer(
            w=w,
            layer=layer,
            catalog_name=getattr(args, f"{layer}_catalog"),
            schema_name=getattr(args, f"{layer}_schema"),
            storage_account_name=getattr(args, f"{layer}_storage_account"),
            access_connector_id=getattr(args, f"{layer}_access_connector_id"),
        )

    log.info("Setup complete.")


if __name__ == "__main__":
    main()
