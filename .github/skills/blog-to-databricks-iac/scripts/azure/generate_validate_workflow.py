from __future__ import annotations

import argparse
from pathlib import Path


def build_workflow_yaml(
    workflow_name: str,
    tenant_input: str,
    subscription_input: str,
) -> str:
    return f"""name: {workflow_name}

on:
  workflow_dispatch:
    inputs:
      {tenant_input}:
        description: Azure tenant ID
        required: true
      {subscription_input}:
        description: Azure subscription ID
        required: true

jobs:
  validate:
    runs-on: ubuntu-latest

    env:
      AZURE_TENANT_ID: ${{{{ github.event.inputs.{tenant_input} }}}}
      AZURE_SUBSCRIPTION_ID: ${{{{ github.event.inputs.{subscription_input} }}}}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Ensure required inputs are set
        run: |
          test -n "$AZURE_TENANT_ID" || (echo "Missing input: {tenant_input}" && exit 1)
          test -n "$AZURE_SUBSCRIPTION_ID" || (echo "Missing input: {subscription_input}" && exit 1)

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init (no backend)
        run: terraform -chdir=infra/terraform init -backend=false

      - name: Terraform Validate
        run: terraform -chdir=infra/terraform validate
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate .github/workflows/validate-terraform.yml"
    )
    parser.add_argument(
        "--output",
        default=".github/workflows/validate-terraform.yml",
        help="Workflow output path.",
    )
    parser.add_argument(
        "--workflow-name",
        default="Validate Terraform",
        help="GitHub Actions workflow display name.",
    )
    parser.add_argument(
        "--tenant-input",
        default="azure_tenant_id",
        help="workflow_dispatch input name for tenant ID.",
    )
    parser.add_argument(
        "--subscription-input",
        default="azure_subscription_id",
        help="workflow_dispatch input name for subscription ID.",
    )

    args = parser.parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    content = build_workflow_yaml(
        workflow_name=args.workflow_name,
        tenant_input=args.tenant_input,
        subscription_input=args.subscription_input,
    )
    output.write_text(content, encoding="utf-8")

    print(f"Generated workflow: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
