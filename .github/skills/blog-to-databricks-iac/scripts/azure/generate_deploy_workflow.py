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
    sp_object_id_secret: str,
    existing_layer_sp_client_id_secret: str,
    existing_layer_sp_object_id_secret: str,
    default_workload: str,
    default_environment: str,
    default_region: str,
) -> str:
    return f"""\
name: {workflow_name}

on:
  workflow_dispatch:
    inputs:
      target:
        description: DAB target to pair with this infrastructure deployment
        required: true
        default: dev
        type: choice
        options: [dev, prd]
      workload:
        description: Workload short name used in Terraform naming
        required: true
        default: {default_workload}
      environment:
        description: Environment value to pass to the downstream DAB deployment
        required: true
        default: {default_environment}
      azure_region:
        description: Azure region for Terraform deployment
        required: true
        default: {default_region}
      layer_sp_mode:
        description: Layer service principal mode (create new or reuse existing)
        required: true
        default: create
        type: choice
        options: [create, existing]

# ARM_* env vars are used by the Terraform AzureRM provider for service-principal auth.
env:
  ARM_TENANT_ID: ${{{{ secrets.{tenant_secret} }}}}
  ARM_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} }}}}
  ARM_CLIENT_ID: ${{{{ secrets.{client_id_secret} }}}}
  ARM_CLIENT_SECRET: ${{{{ secrets.{client_secret_secret} }}}}

jobs:
  deploy_infrastructure:
    runs-on: ubuntu-latest
    environment: {github_environment}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validate required inputs and secrets
        run: |
          missing=()
          for var in ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET; do
            [ -n "${{!var}}" ] || missing+=("$var")
          done
          [ -n "${{{{ secrets.{sp_object_id_secret} }}}}" ] || missing+=("{sp_object_id_secret}")

          if [ "${{{{ github.event.inputs.layer_sp_mode }}}}" = "existing" ]; then
            [ -n "${{{{ secrets.{existing_layer_sp_client_id_secret} }}}}" ] || missing+=("{existing_layer_sp_client_id_secret}")
            [ -n "${{{{ secrets.{existing_layer_sp_object_id_secret} }}}}" ] || missing+=("{existing_layer_sp_object_id_secret}")
          fi

          if [ ${{#missing[@]}} -gt 0 ]; then
            echo "Missing required values: ${{missing[*]}}"
            exit 1
          fi

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false  # Required for clean terraform output -raw

      - name: Terraform Init
        run: terraform -chdir=infra/terraform init

      - name: Terraform Apply
        env:
          TF_VAR_azure_tenant_id: ${{{{ secrets.{tenant_secret} }}}}
          TF_VAR_azure_subscription_id: ${{{{ secrets.{subscription_secret} }}}}
          TF_VAR_azure_client_id: ${{{{ secrets.{client_id_secret} }}}}
          TF_VAR_azure_client_secret: ${{{{ secrets.{client_secret_secret} }}}}
          TF_VAR_azure_sp_object_id: ${{{{ secrets.{sp_object_id_secret} }}}}
          TF_VAR_workload: ${{{{ github.event.inputs.workload }}}}
          TF_VAR_environment: ${{{{ github.event.inputs.environment }}}}
          TF_VAR_azure_region: ${{{{ github.event.inputs.azure_region }}}}
          TF_VAR_layer_service_principal_mode: ${{{{ github.event.inputs.layer_sp_mode }}}}
          TF_VAR_existing_layer_sp_client_id: ${{{{ secrets.{existing_layer_sp_client_id_secret} }}}}
          TF_VAR_existing_layer_sp_object_id: ${{{{ secrets.{existing_layer_sp_object_id_secret} }}}}
        run: terraform -chdir=infra/terraform apply -auto-approve

      - name: Export Terraform outputs
        run: |
          terraform -chdir=infra/terraform output -json > infra/terraform/terraform-outputs.json

      - name: Export deployment context
        run: |
          cat > infra/terraform/deploy-context.json <<'EOF'
          {{
            "target": "${{{{ github.event.inputs.target }}}}",
            "environment": "${{{{ github.event.inputs.environment }}}}",
            "git_sha": "${{{{ github.sha }}}}"
          }}
          EOF

      - name: Upload Terraform outputs artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-outputs
          path: infra/terraform/terraform-outputs.json
          retention-days: 7

      - name: Upload deployment context artifact
        uses: actions/upload-artifact@v4
        with:
          name: deploy-context
          path: infra/terraform/deploy-context.json
          retention-days: 7
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate .github/workflows/deploy-infrastructure.yml — Terraform apply only."
    )
    parser.add_argument("--output", default=".github/workflows/deploy-infrastructure.yml")
    parser.add_argument("--workflow-name", default="Deploy Infrastructure")
    parser.add_argument("--github-environment", default="MYAPP-DEV")
    parser.add_argument("--tenant-secret", default="AZURE_TENANT_ID")
    parser.add_argument("--subscription-secret", default="AZURE_SUBSCRIPTION_ID")
    parser.add_argument("--client-id-secret", default="AZURE_CLIENT_ID")
    parser.add_argument("--client-secret-secret", default="AZURE_CLIENT_SECRET")
    parser.add_argument("--sp-object-id-secret", default="AZURE_SP_OBJECT_ID")
    parser.add_argument("--existing-layer-sp-client-id-secret", default="EXISTING_LAYER_SP_CLIENT_ID")
    parser.add_argument("--existing-layer-sp-object-id-secret", default="EXISTING_LAYER_SP_OBJECT_ID")
    parser.add_argument("--default-workload", default="myapp")
    parser.add_argument("--default-environment", default="dev")
    parser.add_argument("--default-region", default="eastus2")

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
        sp_object_id_secret=args.sp_object_id_secret,
        existing_layer_sp_client_id_secret=args.existing_layer_sp_client_id_secret,
        existing_layer_sp_object_id_secret=args.existing_layer_sp_object_id_secret,
        default_workload=args.default_workload,
        default_environment=args.default_environment,
        default_region=args.default_region,
    )
    output.write_text(content, encoding="utf-8")
    print(f"Generated workflow: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
