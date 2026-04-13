from __future__ import annotations

import argparse
from pathlib import Path


def build_workflow_yaml(
    workflow_name: str,
  github_environment: str,
  tenant_secret: str,
  subscription_secret: str,
    client_id_secret: str,
    client_secret_secret: str,
    databricks_token_secret: str,
) -> str:
    return f"""\
name: {workflow_name}

on:
  workflow_dispatch:
    inputs:
      target:
        description: DAB target (dev or prd)
        required: true
        default: dev
        type: choice
        options: [dev, prd]
      environment:
        description: Environment variable passed to DAB
        required: true
        default: dev

# ARM_* env vars are used by the Terraform AzureRM provider for service-principal auth.
env:
  ARM_TENANT_ID: ${{{{ secrets.{tenant_secret} }}}}
  ARM_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} }}}}
  ARM_CLIENT_ID: ${{{{ secrets.{client_id_secret} }}}}
  ARM_CLIENT_SECRET: ${{{{ secrets.{client_secret_secret} }}}}

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: {github_environment}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validate required inputs and secrets
        env:
          DATABRICKS_TOKEN: ${{{{ secrets.{databricks_token_secret} }}}}
        run: |
          missing=()
          for var in ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET DATABRICKS_TOKEN; do
            [ -n "${{!var}}" ] || missing+=("$var")
          done
          if [ ${{#missing[@]}} -gt 0 ]; then
            echo "Missing required values: ${{missing[*]}}"
            exit 1
          fi

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false  # Required for clean terraform output -raw

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install Databricks CLI
        run: |
          curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

      - name: Terraform Init
        run: terraform -chdir=infra/terraform init

      - name: Terraform Apply
        env:
          TF_VAR_azure_tenant_id: ${{{{ secrets.{tenant_secret} }}}}
          TF_VAR_azure_subscription_id: ${{{{ secrets.{subscription_secret} }}}}
          TF_VAR_databricks_account_id: ${{{{ secrets.DATABRICKS_ACCOUNT_ID }}}}
          TF_VAR_metastore_id: ${{{{ secrets.DATABRICKS_METASTORE_ID }}}}
          TF_VAR_jdbc_host: ${{{{ secrets.JDBC_HOST }}}}
          TF_VAR_jdbc_database: ${{{{ secrets.JDBC_DATABASE }}}}
          TF_VAR_jdbc_user: ${{{{ secrets.JDBC_USER }}}}
          TF_VAR_jdbc_password: ${{{{ secrets.JDBC_PASSWORD }}}}
        run: terraform -chdir=infra/terraform apply -auto-approve

      - name: Get Databricks workspace URL from Terraform
        id: tf_out
        run: |
          ws_url=$(terraform -chdir=infra/terraform output -raw databricks_workspace_url)
          echo "workspace_url=$ws_url" >> "$GITHUB_OUTPUT"

      - name: Deploy Databricks Asset Bundle
        env:
          DATABRICKS_HOST: ${{{{ steps.tf_out.outputs.workspace_url }}}}
          DATABRICKS_TOKEN: ${{{{ secrets.{databricks_token_secret} }}}}
        run: |
          python .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py \\
            --target ${{{{ github.event.inputs.target }}}} \\
            --environment ${{{{ github.event.inputs.environment }}}} \\
            --run
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate .github/workflows/deploy.yml — Terraform apply then DAB deploy."
    )
    parser.add_argument("--output", default=".github/workflows/deploy.yml")
    parser.add_argument("--workflow-name", default="Deploy Infrastructure and DAB")
    parser.add_argument("--github-environment", default="BLG2CODEDEV")
    parser.add_argument("--tenant-secret", default="AZURE_TENANT_ID")
    parser.add_argument("--subscription-secret", default="AZURE_SUBSCRIPTION_ID")
    parser.add_argument("--client-id-secret", default="AZURE_CLIENT_ID")
    parser.add_argument("--client-secret-secret", default="AZURE_CLIENT_SECRET")
    parser.add_argument("--databricks-token-secret", default="DATABRICKS_TOKEN")

    args = parser.parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    content = build_workflow_yaml(
        workflow_name=args.workflow_name,
      github_environment=args.github_environment,
      tenant_secret=args.tenant_secret,
      subscription_secret=args.subscription_secret,
        client_id_secret=args.client_id_secret,
        client_secret_secret=args.client_secret_secret,
        databricks_token_secret=args.databricks_token_secret,
    )
    output.write_text(content, encoding="utf-8")
    print(f"Generated workflow: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
