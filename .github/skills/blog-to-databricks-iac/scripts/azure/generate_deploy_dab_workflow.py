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
      infra_run_id:
        description: Run ID of a successful 'Deploy Infrastructure' workflow run
        required: false
        default: ""
  workflow_run:
    workflows: ["Deploy Infrastructure"]
    types: [completed]

# ARM_* env vars are used by Databricks CLI for Azure service-principal auth.
env:
  ARM_TENANT_ID: ${{{{ secrets.{tenant_secret} }}}}
  ARM_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} }}}}
  ARM_CLIENT_ID: ${{{{ secrets.{client_id_secret} }}}}
  ARM_CLIENT_SECRET: ${{{{ secrets.{client_secret_secret} }}}}

jobs:
  deploy_dab:
    if: ${{{{ github.event_name == 'workflow_dispatch' || (github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'success') }}}}
    runs-on: ubuntu-latest
    environment: {github_environment}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validate required secrets
        run: |
          missing=()
          for var in ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET; do
            [ -n "${{!var}}" ] || missing+=("$var")
          done
          if [ ${{#missing[@]}} -gt 0 ]; then
            echo "Missing required values: ${{missing[*]}}"
            exit 1
          fi

      - name: Resolve infrastructure run ID
        id: resolve_run
        run: |
          if [ "${{{{ github.event_name }}}}" = "workflow_run" ]; then
            run_id="${{{{ github.event.workflow_run.id }}}}"
          else
            run_id="${{{{ github.event.inputs.infra_run_id }}}}"
          fi

          if [ -z "$run_id" ]; then
            echo "infra_run_id is required for workflow_dispatch runs"
            exit 1
          fi

          echo "run_id=$run_id" >> "$GITHUB_OUTPUT"

      - name: Resolve target and environment values
        id: resolve_args
        run: |
          if [ "${{{{ github.event_name }}}}" = "workflow_run" ]; then
            target="dev"
            env_name="dev"
          else
            target="${{{{ github.event.inputs.target }}}}"
            env_name="${{{{ github.event.inputs.environment }}}}"
          fi
          echo "target=$target" >> "$GITHUB_OUTPUT"
          echo "environment=$env_name" >> "$GITHUB_OUTPUT"

      - name: Download Terraform outputs artifact
        uses: actions/download-artifact@v4
        with:
          name: terraform-outputs
          run-id: ${{{{ steps.resolve_run.outputs.run_id }}}}
          github-token: ${{{{ secrets.GITHUB_TOKEN }}}}
          path: infra/terraform

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install Databricks CLI
        run: |
          curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

      - name: Deploy Databricks Asset Bundle
        run: |
          python .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py \\
            --outputs-json-file infra/terraform/terraform-outputs.json \\
            --target ${{{{ steps.resolve_args.outputs.target }}}} \\
            --environment ${{{{ steps.resolve_args.outputs.environment }}}} \\
            --run
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate .github/workflows/deploy-dab.yml — DAB deploy only."
    )
    parser.add_argument("--output", default=".github/workflows/deploy-dab.yml")
    parser.add_argument("--workflow-name", default="Deploy DAB")
    parser.add_argument("--github-environment", default="BLG2CODEDEV")
    parser.add_argument("--tenant-secret", default="AZURE_TENANT_ID")
    parser.add_argument("--subscription-secret", default="AZURE_SUBSCRIPTION_ID")
    parser.add_argument("--client-id-secret", default="AZURE_CLIENT_ID")
    parser.add_argument("--client-secret-secret", default="AZURE_CLIENT_SECRET")

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
    )
    output.write_text(content, encoding="utf-8")
    print(f"Generated workflow: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
