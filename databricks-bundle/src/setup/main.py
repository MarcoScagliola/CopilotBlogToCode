"""
Setup entrypoint — registers Unity Catalog objects (External Locations,
catalogs, schemas) for all three medallion layers.

This script is executed as a Databricks Lakeflow job task before any
layer job runs.
"""
import argparse
import sys


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Register Unity Catalog objects for the medallion layers."
    )

    for layer in ("bronze", "silver", "gold"):
        parser.add_argument(
            f"--{layer}-catalog",
            required=True,
            help=f"Unity Catalog catalog name for the {layer.capitalize()} layer.",
        )
        parser.add_argument(
            f"--{layer}-schema",
            required=True,
            help=f"Unity Catalog schema name for the {layer.capitalize()} layer.",
        )
        parser.add_argument(
            f"--{layer}-storage-account",
            required=True,
            help=f"ADLS Gen2 storage account name for the {layer.capitalize()} layer.",
        )
        parser.add_argument(
            f"--{layer}-access-connector-id",
            required=True,
            help=f"Databricks Access Connector resource ID for the {layer.capitalize()} layer.",
        )

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    for layer in ("bronze", "silver", "gold"):
        catalog = getattr(args, f"{layer}_catalog")
        schema = getattr(args, f"{layer}_schema")
        storage_account = getattr(args, f"{layer}_storage_account")
        access_connector_id = getattr(args, f"{layer}_access_connector_id")
        print(
            f"[setup] {layer}: catalog={catalog}, schema={schema}, "
            f"storage_account={storage_account}, "
            f"access_connector_id={access_connector_id}"
        )

    # TODO: implement Unity Catalog External Location registration,
    # catalog creation, and schema creation for each layer.
    print("[setup] Setup stub complete — replace with Unity Catalog API calls.")


if __name__ == "__main__":
    main(sys.argv[1:])
