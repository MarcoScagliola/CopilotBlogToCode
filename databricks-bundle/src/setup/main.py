import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Setup Unity Catalog objects and external locations.")
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
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    layers = ["bronze", "silver", "gold"]
    for layer in layers:
        catalog = getattr(args, f"{layer}_catalog")
        schema = getattr(args, f"{layer}_schema")
        storage = getattr(args, f"{layer}_storage_account")
        connector = getattr(args, f"{layer}_access_connector_id")
        print(f"[{layer}] catalog={catalog} schema={schema} storage={storage} connector={connector}")

    # TODO: Implement Unity Catalog catalog/schema creation and external location registration.


if __name__ == "__main__":
    main()
