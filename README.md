# Secure Medallion Architecture on Azure Databricks

This repository implements the Azure Databricks architecture pattern from:

- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Infrastructure is provisioned with Terraform. Databricks jobs are deployed with a Databricks Asset Bundle (DAB). CI/CD is split across three GitHub Actions workflows.

## Prerequisites

- Azure subscription with Contributor access for the deployment principal.
- Permission in Microsoft Entra ID to create app registrations/service principals if using `layer_sp_mode=create`.
- GitHub Environment `BLG2CODEDEV` configured with required secrets/variables.
- Terraform CLI >= 1.6 and Python 3.11+ for local validation.

## Required GitHub Secrets and Variables

### Always required

| Name | Description |
|---|---|
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment service principal client ID |
| `AZURE_CLIENT_SECRET` | Deployment service principal secret |
| `AZURE_SP_OBJECT_ID` | Deployment service principal object ID (Enterprise Applications object ID) |

### Required when `layer_sp_mode=existing`

| Name | Description |
|---|---|
| `EXISTING_LAYER_SP_CLIENT_ID` | Existing layer principal client ID |
| `EXISTING_LAYER_SP_OBJECT_ID` | Existing layer principal object ID (Enterprise Applications object ID) |

Important: `*_SP_OBJECT_ID` values must be Service Principal object IDs from Entra ID -> Enterprise applications.

## Architecture Design

- Medallion layers: Bronze -> Silver -> Gold.
- One orchestrator job executes setup and then runs each layer job sequentially.
- Isolation by design:
	- Separate storage account per layer.
	- Dedicated principal identity per layer.
	- Dedicated Databricks job cluster per layer.
- Secrets remain in Azure Key Vault and are read at runtime.
- Unity Catalog is used for catalog/schema/table governance.

## Workflows

### 1. Validate Terraform

- File: `.github/workflows/validate-terraform.yml`
- Trigger: `workflow_dispatch`
- Runs `terraform init -backend=false` and `terraform validate`.

### 2. Deploy Infrastructure

- File: `.github/workflows/deploy-infrastructure.yml`
- Trigger: `workflow_dispatch`
- Inputs: `target`, `workload`, `environment`, `azure_region`, `layer_sp_mode`, `state_strategy`, `key_vault_recovery_mode`
- Default values in this implementation:
	- `workload=etl`
	- `environment=dev`
	- `azure_region=uksouth`
	- `layer_sp_mode=create` (workflow default; set to `existing` for this run context)
- Uploads artifacts:
	- `terraform-outputs`
	- `deploy-context`

### 3. Deploy DAB

- File: `.github/workflows/deploy-dab.yml`
- Trigger:
	- automatic after successful infrastructure deployment (`workflow_run`), or
	- manual (`workflow_dispatch`) with `infra_run_id`
- Downloads outputs artifacts and deploys Databricks Asset Bundle.

## Local Terraform Steps

```bash
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan \
	-var="tenant_id=$AZURE_TENANT_ID" \
	-var="subscription_id=$AZURE_SUBSCRIPTION_ID" \
	-var="deployment_sp_object_id=$AZURE_SP_OBJECT_ID" \
	-var="workload=etl" \
	-var="environment=dev" \
	-var="azure_region=uksouth" \
	-var="layer_sp_mode=existing" \
	-var="existing_layer_sp_client_id=$EXISTING_LAYER_SP_CLIENT_ID" \
	-var="existing_layer_sp_object_id=$EXISTING_LAYER_SP_OBJECT_ID"
```

## Databricks Bundle Steps

```bash
databricks bundle validate --target dev
databricks bundle deploy --target dev
databricks bundle run orchestrator_job --target dev
databricks bundle run smoke_test_job --target dev
```

`orchestrator_job` runs the smoke test automatically after `run_gold`. You can also run `smoke_test_job` independently for quick post-run verification.

## Post-Deploy Contract Checklist

Validate Terraform outputs and Databricks bundle variable wiring automatically:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --outputs-json-file infra/terraform/terraform-outputs.json
```

If you want to validate contract structure before Terraform apply/state exists:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
```

## Assumptions

- The article (Part I) is architecture-first and does not provide all concrete runtime parameters.
- Source ingestion details are intentionally sample placeholders in Bronze code and must be replaced.
- Networking hardening details (private endpoints/VNet topology) are not fully specified in the source article and remain TODO items.

## Additional Docs

- `SPEC.md` for architecture extraction and explicit vs inferred assumptions.
- `TODO.md` for unresolved values and post-deployment actions.
