# Architecture Specification - Secure Medallion on Azure Databricks

## Objective

Implement a least-privilege medallion architecture (Bronze, Silver, Gold) on Azure Databricks where:
- each layer runs as a dedicated Lakeflow job
- each layer has isolated ADLS Gen2 storage and principal access
- secrets are managed in Azure Key Vault
- an orchestrator runs Bronze then Silver then Gold

## Design Summary

- Identity mode supports both:
  - create: create one Entra application/service principal per layer
  - existing: reuse a pre-created service principal
- Storage isolation uses one account per layer (`st...bronze`, `st...silver`, `st...gold`).
- Key Vault access policy is bound to the running Terraform identity (`azurerm_client_config.current`).
- Terraform outputs include both `databricks_workspace_url` and `databricks_workspace_resource_id` for DAB deployment bridge compatibility.

## CI/CD Summary

- Validate workflow: Terraform init/validate checks.
- Deploy infrastructure workflow: applies Terraform and exports deployment artifacts.
- Deploy DAB workflow: consumes artifacts and deploys Databricks Asset Bundle.

## Naming Convention

- Resource group: `rg-<workload>-<environment>-platform`
- Databricks workspace: `dbw-<workload>-<environment>`
- Layer apps: `app-<workload>-<environment>-<layer>`
- Layer storage accounts: `st<workload><environment><layer>` (truncated to 24 chars)

## Post-Deployment Requirements

- Create Unity Catalog catalogs and schemas per layer.
- Grant layer principals required catalog privileges.
- Configure Key Vault-backed secret scopes in Databricks.
