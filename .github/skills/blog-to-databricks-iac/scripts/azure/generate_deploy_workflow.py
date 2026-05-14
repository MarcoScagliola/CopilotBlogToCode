from __future__ import annotations

import argparse
from pathlib import Path


def build_workflow_yaml(
    workflow_name: str,
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
      key_vault_recovery_mode:
        description: Key Vault soft-delete handling mode
        required: true
        default: auto
        type: choice
        options: [auto, recover, fresh]
      state_strategy:
        description: How to handle pre-existing Azure resources when state is ephemeral
        required: true
        default: fail
        type: choice
        options: [fail, recreate_rg]

env:
  ARM_TENANT_ID: ${{{{ secrets.{tenant_secret} || vars.{tenant_secret} }}}}
  ARM_SUBSCRIPTION_ID: ${{{{ secrets.{subscription_secret} || vars.{subscription_secret} }}}}
  ARM_CLIENT_ID: ${{{{ secrets.{client_id_secret} || vars.{client_id_secret} }}}}
  ARM_CLIENT_SECRET: ${{{{ secrets.{client_secret_secret} || vars.{client_secret_secret} }}}}
  ARM_SP_OBJECT_ID: ${{{{ secrets.{sp_object_id_secret} || vars.{sp_object_id_secret} }}}}

jobs:
  deploy_infrastructure:
    runs-on: ubuntu-latest
    environment: ${{{{ github.event.inputs.workload }}}}-${{{{ github.event.inputs.environment }}}}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validate required inputs and secrets
        run: |
          missing=()
          for var in ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_SP_OBJECT_ID; do
            [ -n "${{!var}}" ] || missing+=("$var")
          done
          if [ ${{#missing[@]}} -gt 0 ]; then
            echo "Missing required values: ${{missing[*]}}"
            exit 1
          fi

      - name: Compute canonical resource names
        run: |
          region="${{{{ github.event.inputs.azure_region }}}}"
          case "$region" in
            eastus) region_abbr="eus" ;;
            eastus2) region_abbr="eus2" ;;
            westus2) region_abbr="wus2" ;;
            westeurope) region_abbr="weu" ;;
            northeurope) region_abbr="neu" ;;
            uksouth) region_abbr="uks" ;;
            ukwest) region_abbr="ukw" ;;
            *) region_abbr="${{region// /}}" ;;
          esac

          workload="${{{{ github.event.inputs.workload }}}}"
          environment="${{{{ github.event.inputs.environment }}}}"

          rg_name="rg-$workload-$environment-$region_abbr"
          kv_name="kv-$workload-$environment-$region_abbr"
          kv_name="${{kv_name//_/}}"
          kv_name="${{kv_name:0:24}}"
          workspace_name="dbw-$workload-$environment-$region_abbr"
          bronze_storage_name="$(echo "st${{workload}}${{environment}}bronze${{region_abbr}}" | tr '[:upper:]' '[:lower:]' | cut -c1-24)"
          silver_storage_name="$(echo "st${{workload}}${{environment}}silver${{region_abbr}}" | tr '[:upper:]' '[:lower:]' | cut -c1-24)"
          gold_storage_name="$(echo "st${{workload}}${{environment}}gold${{region_abbr}}" | tr '[:upper:]' '[:lower:]' | cut -c1-24)"

          echo "REGION_ABBR=$region_abbr" >> "$GITHUB_ENV"
          echo "RG_NAME=$rg_name" >> "$GITHUB_ENV"
          echo "KV_NAME=$kv_name" >> "$GITHUB_ENV"
          echo "WORKSPACE_NAME=$workspace_name" >> "$GITHUB_ENV"
          echo "BRONZE_STORAGE_NAME=$bronze_storage_name" >> "$GITHUB_ENV"
          echo "SILVER_STORAGE_NAME=$silver_storage_name" >> "$GITHUB_ENV"
          echo "GOLD_STORAGE_NAME=$gold_storage_name" >> "$GITHUB_ENV"

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false

      - name: Enforce restricted-tenant guardrails
        run: |
          if grep -R -qE 'data[[:space:]]+"azuread_' infra/terraform/; then
            echo "Forbidden azuread data source detected in infra/terraform/."
            echo "This baseline must work in restricted tenants without Microsoft Graph reads."
            exit 1
          fi

      - name: Azure CLI login for state preflight
        run: |
          az login --service-principal --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" 1>/dev/null
          az account set --subscription "$ARM_SUBSCRIPTION_ID"

      - name: Handle existing resource group when state is ephemeral
        run: |
          exists=$(az group exists --name "$RG_NAME")
          if [ "$exists" = "true" ]; then
            if [ "${{{{ github.event.inputs.state_strategy }}}}" = "recreate_rg" ]; then
              echo "Resource group '$RG_NAME' exists. Deleting because state_strategy=recreate_rg."
              az group delete --name "$RG_NAME" --yes --no-wait
              az group wait --name "$RG_NAME" --deleted
            else
              echo "Resource group '$RG_NAME' already exists but this run has no persisted Terraform state."
              echo "Choose state_strategy=recreate_rg for ephemeral reruns, or configure a remote backend + import."
              exit 1
            fi
          fi

      - name: Terraform Init
        run: terraform -chdir=infra/terraform init

      - name: Detect Key Vault soft-delete recovery mode
        run: |
          mode="${{{{ github.event.inputs.key_vault_recovery_mode }}}}"
          if [ "$mode" = "recover" ]; then
            recover=true
            deleted_count=manual
          elif [ "$mode" = "fresh" ]; then
            recover=false
            deleted_count=manual
          else
            recover=true
            deleted_count=unknown
            set +e
            detected_count=$(az keyvault list-deleted --query "[?name=='$KV_NAME'] | length(@)" -o tsv 2>/dev/null)
            rc=$?
            set -e
            if [ $rc -eq 0 ] && [ -n "$detected_count" ]; then
              deleted_count="$detected_count"
            else
              echo "Could not query deleted vaults in auto mode; continuing with recovery-first strategy."
            fi
          fi

          echo "TF_VAR_key_vault_recover_soft_deleted=$recover" >> "$GITHUB_ENV"
          echo "KeyVaultDecision mode=$mode effective_recover=$recover kv_name=$KV_NAME deleted_match_count=$deleted_count"

      - name: Terraform Apply
        env:
          TF_VAR_tenant_id: ${{{{ env.ARM_TENANT_ID }}}}
          TF_VAR_subscription_id: ${{{{ env.ARM_SUBSCRIPTION_ID }}}}
          TF_VAR_client_id: ${{{{ env.ARM_CLIENT_ID }}}}
          TF_VAR_client_secret: ${{{{ env.ARM_CLIENT_SECRET }}}}
          TF_VAR_sp_object_id: ${{{{ env.ARM_SP_OBJECT_ID }}}}
          TF_VAR_workload: ${{{{ github.event.inputs.workload }}}}
          TF_VAR_environment: ${{{{ github.event.inputs.environment }}}}
          TF_VAR_azure_region: ${{{{ github.event.inputs.azure_region }}}}
        run: |
          current_recover="${{TF_VAR_key_vault_recover_soft_deleted:-true}}"
          export TF_VAR_key_vault_recover_soft_deleted="$current_recover"
          echo "TerraformApply resolved_key_vault_recover_soft_deleted=$TF_VAR_key_vault_recover_soft_deleted"

          set +e
          terraform -chdir=infra/terraform apply -auto-approve -input=false -parallelism=1 -var="key_vault_recover_soft_deleted=$current_recover" 2>&1 | tee /tmp/tf-apply.log
          rc=${{PIPESTATUS[0]}}
          set -e

          if [ $rc -eq 0 ]; then
            exit 0
          fi

          if grep -Eqi "No value for required variable|Invalid value for variable" /tmp/tf-apply.log; then
            echo "Configuration error detected — refusing to retry"
            exit $rc
          fi

          if grep -Eqi "SoftDeletedVaultDoesNotExist|soft[- ]deleted.*does not exist" /tmp/tf-apply.log; then
            echo "Detected SoftDeletedVaultDoesNotExist. Retrying with key_vault_recover_soft_deleted=false."
            terraform -chdir=infra/terraform apply -auto-approve -input=false -parallelism=1 -var='key_vault_recover_soft_deleted=false'
            exit 0
          fi

          if grep -Eqi "recovering this KeyVault has been disabled|existing soft-deleted Key Vault exists" /tmp/tf-apply.log; then
            echo "Detected recovery-disabled Key Vault error. Recovering vault and importing into Terraform state."
            az group create --name "$RG_NAME" --location "${{{{ github.event.inputs.azure_region }}}}" 1>/dev/null
            az keyvault recover --name "$KV_NAME"
            for attempt in 1 2 3 4 5 6; do
              if az keyvault show --name "$KV_NAME" 1>/dev/null 2>/dev/null; then
                break
              fi
              sleep 10
            done
            actual_rg=$(az keyvault show --name "$KV_NAME" --query resourceGroup -o tsv)
            if [ "$actual_rg" != "$RG_NAME" ]; then
              echo "Recovered vault '$KV_NAME' is in resource group '$actual_rg', but the current Terraform configuration expects it in '$RG_NAME'."
              echo "This indicates a legacy deployment using a different naming convention. Purge the soft-deleted vault permanently and rerun with key_vault_recovery_mode=fresh after backup if needed."
              exit 1
            fi
            if ! terraform -chdir=infra/terraform state show azurerm_key_vault.main 1>/dev/null 2>/dev/null; then
              terraform -chdir=infra/terraform import azurerm_key_vault.main "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/$KV_NAME"
            fi
            terraform -chdir=infra/terraform apply -auto-approve -input=false -parallelism=1 -var='key_vault_recover_soft_deleted=true'
            exit 0
          fi

          if grep -Eqi "to be managed via Terraform this resource needs to be imported|already exists - to be managed via Terraform" /tmp/tf-apply.log; then
            echo "Detected existing active Key Vault not in state. Importing and retrying apply."
            if ! terraform -chdir=infra/terraform state show azurerm_key_vault.main 1>/dev/null 2>/dev/null; then
              terraform -chdir=infra/terraform import azurerm_key_vault.main "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/$KV_NAME"
            fi
            terraform -chdir=infra/terraform apply -auto-approve -input=false -parallelism=1 -var="key_vault_recover_soft_deleted=$current_recover"
            exit 0
          fi

          echo "Manual intervention required: Terraform apply failed with an unhandled error class."
          exit $rc

      - name: Export Terraform outputs
        run: terraform -chdir=infra/terraform output -json > infra/terraform/terraform-outputs.json

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