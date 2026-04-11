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

1. Fill unresolved values in `TODO.md`.
2. Create `infra/terraform/terraform.tfvars` with required inputs.
3. Run Terraform:
   - `terraform -chdir=infra/terraform init`
   - `terraform -chdir=infra/terraform validate`
   - `terraform -chdir=infra/terraform apply -var-file=terraform.tfvars`
4. Store secrets in Key Vault:
   - `jdbc-connection-string`
   - `jdbc-username`
   - `jdbc-password`
   - `source-table-name`
5. Update `databricks-bundle/databricks.yml` using Terraform outputs.
6. Validate and deploy DAB:
   - `cd databricks-bundle`
   - `databricks bundle validate`
   - `databricks bundle deploy`

## Notes

- Names are derived in `infra/terraform/locals.tf` from `workload`, `environment`, `azure_region`.
- No resource names should be passed as Terraform variables.
- Region policy is explicit and does not assume defaults.
