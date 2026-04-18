# SPEC - Secure Medallion Architecture on Azure Databricks

## Objective
Implement a secure medallion pattern from the referenced blog using Azure-native identity, storage isolation, and Databricks job orchestration.

## Scope
- Provision base Azure platform components with Terraform.
- Create three isolated medallion storage layers: bronze, silver, gold.
- Create layer identity model with either:
  - `create`: one dedicated Entra application/service principal per layer.
  - `existing`: reuse a pre-existing service principal for layer execution.
- Provision Azure Databricks workspace and export workspace metadata for bundle deployment.
- Deploy Databricks Asset Bundle jobs for bronze, silver, gold, and orchestrator.
- Implement split CI/CD workflows:
  - Validate Terraform
  - Deploy Infrastructure
  - Deploy DAB

## Architecture Decisions
1. Identity isolation
- Layer identities are represented as service principals.
- Role assignments use `principal_type = "ServicePrincipal"`.
- Existing-mode validates the provided principal object ID via Azure AD data source.

2. Storage isolation
- Dedicated ADLS Gen2 storage account per medallion layer.
- Private containers per layer and RBAC-scoped access.

3. Secret handling
- Azure Key Vault stores layer storage account names.
- Key Vault access policy is granted to the executing deployment principal object ID (`azurerm_client_config.current.object_id`).

4. Databricks deployment bridge
- Terraform exports both `databricks_workspace_url` and `databricks_workspace_resource_id`.
- DAB deployment script maps Terraform outputs to bundle variables.

5. Workflow handoff model
- Infrastructure workflow publishes `terraform-outputs` and `deploy-context` artifacts.
- DAB workflow consumes artifacts and deploys matching commit SHA.

## Naming Convention
Names are derived from:
- `workload`
- `environment`
- `azure_region`

Base pattern:
- Resource group: `rg-<workload>-<environment>-platform`
- Key Vault: `kv-<workload>-<environment>-<suffix>`
- Databricks workspace: `dbw-<workload>-<environment>`

## Security and Access Model
- Authentication is service principal-based in CI/CD.
- GitHub workflow credentials resolve from `secrets.<NAME> || vars.<NAME>`.
- `AZURE_SP_OBJECT_ID` and `EXISTING_LAYER_SP_OBJECT_ID` must be Service Principal (Enterprise Application) object IDs.

## Output Contract
Terraform outputs consumed by DAB deployment:
- `databricks_workspace_url`
- `databricks_workspace_resource_id`
- `bronze_sp_application_id`
- `silver_sp_application_id`
- `gold_sp_application_id`
- `bronze_catalog_name`
- `silver_catalog_name`
- `gold_catalog_name`
- `secret_scope_name`
