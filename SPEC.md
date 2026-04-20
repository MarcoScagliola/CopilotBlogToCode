# SPEC - Secure Medallion Architecture on Azure Databricks (Part I)

## Source

- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Objective

Implement a secure Medallion pattern on Azure Databricks where Bronze, Silver, and Gold are isolated by identity, storage, and compute. Use Terraform for Azure infrastructure and Databricks Asset Bundle for Lakeflow jobs.

## Scope

### Infrastructure (Terraform)

- Resource group: platform boundary for all resources
- Databricks workspace: Premium SKU
- ADLS Gen2 storage accounts: one per layer (Bronze/Silver/Gold)
- ADLS filesystems: one per layer
- Databricks Access Connectors: one per layer
- Key Vault: centralized secret store with RBAC enabled
- Layer principals:
  - `layer_sp_mode=create`: create app registrations and service principals per layer
  - `layer_sp_mode=existing`: reuse a pre-created service principal, no Graph lookup dependency
- RBAC assignments:
  - Layer principal -> Storage Blob Data Contributor on its storage account
  - Access connector identity -> Storage Blob Data Contributor on its storage account
  - Deployment principal -> Key Vault Secrets Officer

### Data plane deployment (DAB)

- Bronze job (raw ingestion)
- Silver job (refinement and deduplication)
- Gold job (curation and aggregation)
- Orchestrator job chaining Bronze -> Silver -> Gold
- Dedicated job cluster definition per layer task
- Runtime parameters for catalog/schema/scope (no hardcoded environment paths)

### CI/CD workflows

- Validate Terraform workflow
- Deploy Infrastructure workflow
- Deploy DAB workflow
- Artifact bridge from infra outputs to DAB variables

## Security Design

1. Identity isolation
   - Separate service principal context per layer when in create mode.
   - Existing-mode fallback for restricted tenants that cannot create app registrations.

2. Storage isolation
   - Physical separation of data by storage account per layer.

3. Compute isolation
   - Dedicated job cluster definition per layer job.

4. Secret handling
   - Key Vault for secrets; Databricks secret scope expected post-provisioning.

5. Least privilege
   - Layer identities only receive layer-specific storage RBAC.

## Naming Strategy

Derived in `locals.tf` from:

- `workload`
- `environment`
- `azure_region`

Examples in this run context (`blg`, `dev`, `eastus2`):

- Resource group: `rg-blg-dev-platform`
- Databricks workspace: `dbw-blg-dev`
- Layer storage accounts: `stblgbrzdev`, `stblgslvdev`, `stblgglddev`

## Required Terraform Outputs

The DAB bridge depends on these outputs:

- `databricks_workspace_url`
- `databricks_workspace_resource_id`
- `layer_principal_client_ids`
- `layer_storage_account_names`
- `bronze_catalog_name`
- `silver_catalog_name`
- `gold_catalog_name`
- `secret_scope_name`

## Assumptions

- GitHub environment `BLG2CODEDEV` contains all required Azure credentials.
- Deployment principal already has sufficient Azure RBAC to create resources and assignments.
- Unity Catalog resources (catalogs/schemas/external locations) are completed post-provisioning.
- Databricks service principal entitlements and workspace assignments are completed where required.

## Out of Scope

- Production network hardening (private endpoints, VNet injection) beyond this baseline.
- Full Unity Catalog object provisioning via Terraform.
- Source-system connector secrets and ingestion logic specifics.
