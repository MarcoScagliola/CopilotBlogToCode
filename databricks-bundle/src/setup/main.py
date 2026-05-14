from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Setup medallion Unity Catalog baseline.")
    parser.add_argument("--workspace-resource-id", required=True)
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
    parser.add_argument("--bronze-principal-client-id", required=True)
    parser.add_argument("--silver-principal-client-id", required=True)
    parser.add_argument("--gold-principal-client-id", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    print("setup completed")
    print(f"workspace_resource_id={args.workspace_resource_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
