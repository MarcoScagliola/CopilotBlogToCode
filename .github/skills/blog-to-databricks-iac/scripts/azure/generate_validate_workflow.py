from __future__ import annotations

import argparse
from pathlib import Path


def build_workflow_yaml(
    workflow_name: str,
    github_environment: str,
    tenant_secret: str,
    subscription_secret: str,
) -> str:
    return f"""name: {workflow_name}

on:
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    environment: {github_environment}

    env:
      AZURE_TENANT_ID: ${{{{ secrets.{tenant_secret} || vars.{tenant_secret} }}}}
      AZURE_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} || vars.{subscription_secret} }}}}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Ensure required environment secrets are set
        run: |
          missing=()
          [ -n "$AZURE_TENANT_ID" ] || missing+=("{tenant_secret}")
          [ -n "$AZURE_SUBSCRIPTION_ID" ] || missing+=("{subscription_secret}")
          if [ ${{#missing[@]}} -gt 0 ]; then
            echo "Missing required values: ${{missing[*]}}"
            exit 1
          fi

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Enforce existing-principal compatibility guardrails
        run: |
          # Prevent regressions that require Microsoft Graph directory-read permissions in restricted tenants.
          if grep -q 'data "azuread_service_principal" "existing_layer"' infra/terraform/main.tf; then
            echo 'Forbidden pattern detected: data "azuread_service_principal" "existing_layer"'
            echo "Use existing_layer_sp_object_id input directly for RBAC principal_id in existing mode."
            exit 1
          fi

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
        "--github-environment",
        default="BLG2CODEDEV",
        help="GitHub Actions environment name.",
    )
    parser.add_argument(
        "--tenant-secret",
        default="AZURE_TENANT_ID",
        help="Environment secret name for tenant ID.",
    )
    parser.add_argument(
        "--subscription-secret",
        default="AZURE_SUBSCRIPTION_ID",
        help="Environment secret name for subscription ID.",
    )

    args = parser.parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    content = build_workflow_yaml(
        workflow_name=args.workflow_name,
        github_environment=args.github_environment,
        tenant_secret=args.tenant_secret,
        subscription_secret=args.subscription_secret,
    )
    output.write_text(content, encoding="utf-8")

    print(f"Generated workflow: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
