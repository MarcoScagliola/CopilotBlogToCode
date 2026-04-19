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
        description: Optional DAB target override. Leave empty to reuse the infrastructure deployment context.
        required: false
        default: ""
      environment:
        description: Optional environment override. Leave empty to reuse the infrastructure deployment context.
        required: false
        default: ""
      infra_run_id:
        description: Run ID of a successful 'Deploy Infrastructure' workflow run
        required: true
        default: ""
  workflow_run:
    workflows: ["Deploy Infrastructure"]
    types: [completed]

permissions:
  actions: read
  contents: read

# ARM_* env vars are used by Databricks CLI for Azure service-principal auth.
env:
  ARM_TENANT_ID: ${{{{ secrets.{tenant_secret} || vars.{tenant_secret} }}}}
  ARM_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} || vars.{subscription_secret} }}}}
  ARM_CLIENT_ID: ${{{{ secrets.{client_id_secret} || vars.{client_id_secret} }}}}
  ARM_CLIENT_SECRET: ${{{{ secrets.{client_secret_secret} || vars.{client_secret_secret} }}}}

jobs:
  deploy_dab:
    if: ${{{{ github.event_name == 'workflow_dispatch' || (github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'success') }}}}
    runs-on: ubuntu-latest
    environment: {github_environment}

    steps:
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

      - name: Download deployment context artifact
        uses: actions/download-artifact@v4
        with:
          name: deploy-context
          run-id: ${{{{ steps.resolve_run.outputs.run_id }}}}
          github-token: ${{{{ secrets.GITHUB_TOKEN }}}}
          path: infra/terraform

      - name: Resolve target, environment, and git ref
        id: resolve_args
        run: |
          context_file="infra/terraform/deploy-context.json"
          if [ ! -f "$context_file" ]; then
            echo "deploy-context artifact not found at $context_file"
            exit 1
          fi

          context_target=$(python -c "import json; print(json.load(open('$context_file', encoding='utf-8'))['target'])")
          context_environment=$(python -c "import json; print(json.load(open('$context_file', encoding='utf-8'))['environment'])")
          context_git_sha=$(python -c "import json; print(json.load(open('$context_file', encoding='utf-8'))['git_sha'])")

          if [ "${{{{ github.event_name }}}}" = "workflow_dispatch" ] && [ -n "${{{{ github.event.inputs.target }}}}" ]; then
            target="${{{{ github.event.inputs.target }}}}"
          else
            target="$context_target"
          fi

          if [ "${{{{ github.event_name }}}}" = "workflow_dispatch" ] && [ -n "${{{{ github.event.inputs.environment }}}}" ]; then
            env_name="${{{{ github.event.inputs.environment }}}}"
          else
            env_name="$context_environment"
          fi

          echo "target=$target" >> "$GITHUB_OUTPUT"
          echo "environment=$env_name" >> "$GITHUB_OUTPUT"
          echo "git_ref=$context_git_sha" >> "$GITHUB_OUTPUT"

      - name: Checkout matching infrastructure commit
        uses: actions/checkout@v4
        with:
          ref: ${{{{ steps.resolve_args.outputs.git_ref }}}}

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
