# TODO - Secure Medallion Architecture

## Required Before First Deployment
- Confirm deployment principal has:
  - Subscription/resource-group Contributor rights.
  - Directory permissions required to create applications/service principals when `layer_service_principal_mode=create`.
- Confirm Databricks workspace creation is allowed in the target subscription and region.
- Populate GitHub Environment `BLG2CODEDEV` with:
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_SP_OBJECT_ID` (Service Principal object ID from Enterprise Applications)
  - Optional for existing mode:
    - `EXISTING_LAYER_SP_CLIENT_ID`
    - `EXISTING_LAYER_SP_OBJECT_ID`

## Data and Catalog Setup
- Create/validate Unity Catalog catalogs and schema permissions expected by jobs:
  - `<env>_bronze.ingestion`
  - `<env>_silver.refined`
  - `<env>_gold.curated`
- Replace sample bronze ingestion logic with source-specific extraction.

## Security Hardening Follow-up
- Add rotation and expiration policies for Key Vault secrets.
- Review whether additional Key Vault RBAC/access policies are needed for runtime principals.
- Add monitoring/alerts for job failures and cost per medallion layer.

## Validation and Testing
- Run a full deployment in `dev` and execute `orchestrator_job` end-to-end.
- Add smoke checks that validate table creation after bronze/silver/gold runs.
- Add CI checks for Terraform formatting (`terraform fmt -check`) and static linting.
