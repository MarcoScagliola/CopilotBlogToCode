# Secure Medallion Architecture on Azure Databricks

This repo contains an implementation-ready scaffold of the architecture described in:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## What Was Generated

- `SPEC.md`
- `TODO.md`
- Terraform under `infra/terraform/`
- Databricks DAB under `databricks-bundle/`

## Execution Inputs For This Run

- `azure_region = uksouth`
- `workload = blg`
- `environment = dev`

## Ownership Boundary

Terraform owns:
- Resource group
- Databricks workspace
- ADLS Gen2 storage and filesystems
- Access connectors
- Entra applications and service principals
- Key Vault
- Unity Catalog storage credentials, external locations, catalogs, schemas

DAB owns:
- Bronze/Silver/Gold jobs
- Orchestrator job
- Python entrypoints

## Deploy Steps

### Step 1 — Terraform
1. Fill unresolved values in `TODO.md`.
2. Create `infra/terraform/terraform.tfvars` with required inputs.
3. Run Terraform:
   ```bash
   terraform -chdir=infra/terraform init
   terraform -chdir=infra/terraform validate
   terraform -chdir=infra/terraform apply -var-file=terraform.tfvars
   ```
4. Store JDBC secrets in Key Vault (once workspace is provisioned):
   - `jdbc-host`
   - `jdbc-database`
   - `jdbc-user`
   - `jdbc-password`

### Step 2 — Databricks Asset Bundle
The bridge script reads all Terraform outputs and wires them directly into the bundle deploy command — no manual copy-paste of workspace IDs, SP client IDs, or catalog names.

**Preview the generated command (dry run):**
```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py \
  --target dev \
  --environment dev
```

**Execute the deploy:**
```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py \
  --target dev \
  --environment dev \
  --run
```

The script maps these Terraform outputs to DAB variables automatically:

| Terraform output | DAB variable |
|-----------------|-------------|
| `databricks_workspace_url` | `workspace_host` |
| `bronze_sp_client_id` | `bronze_sp_client_id` |
| `silver_sp_client_id` | `silver_sp_client_id` |
| `gold_sp_client_id` | `gold_sp_client_id` |
| `uc_catalog_bronze` | `bronze_catalog` |
| `uc_catalog_silver` | `silver_catalog` |
| `uc_catalog_gold` | `gold_catalog` |
| `secret_scope_name` | `secret_scope` |

## Notes

- Names are derived in `infra/terraform/locals.tf` from `workload`, `environment`, `azure_region`.
- No resource names should be passed as Terraform variables.
- Region policy is explicit and does not assume defaults.

## GitHub Secure Variables

To let contributors reuse this repo safely, configure these repository-level GitHub secrets:

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Set them with GitHub CLI:

```bash
gh secret set AZURE_TENANT_ID --body "<your-tenant-id>"
gh secret set AZURE_SUBSCRIPTION_ID --body "<your-subscription-id>"
```

Or in GitHub UI:

1. Open `Settings` > `Secrets and variables` > `Actions`.
2. Create the two secrets above.

This repo includes `.github/workflows/validate-terraform.yml`, which reads those secrets and runs Terraform validation in CI.
