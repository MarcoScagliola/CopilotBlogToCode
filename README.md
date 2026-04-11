# Secure Medallion Architecture – Terraform + Databricks DAB

Implementation-ready code for deploying a secure Medallion Architecture on Azure Databricks with per-layer isolation, least-privilege access, and governance via Unity Catalog.

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture Overview

**Three-layer medallion with per-layer isolation:**
- **Bronze:** Raw data ingestion from JDBC source via dedicated service principal
- **Silver:** Data transformation (deduplication, filtering) with read-only access to Bronze
- **Gold:** Business aggregations with read-only access to Silver

**Security & Isolation:**
- Dedicated Azure storage account per layer (ADLS Gen2)
- Dedicated Entra ID service principal per layer (least-privilege RBAC)
- Dedicated job cluster per layer (compute isolation)
- Separate Lakeflow job per layer + orchestrator job (clear separation of duties)
- Unity Catalog for governance (catalogs, schemas, storage credentials, external locations)
- Azure Key Vault for secrets management (AKV-backed Databricks secret scope)

**Resources:** 3× storage accounts, 3× access connectors, 3× Entra SPs, 1× Key Vault, 1× workspace, 3× UC catalogs, 4 Lakeflow jobs

## Deployment Steps

### 1. Prepare Configuration

Fill in `TODO.md`. Resource names are **auto-derived** from three inputs — you don't supply them:

| Input | Description | Example |
|-------|-------------|---------|
| `workload` | Short project identifier (4–6 chars) | `mdln` |
| `environment` | Deployment environment | `dev`, `prod` |
| `azure_region` | Azure region | `uksouth` (default) |

You must supply:
- Azure tenant ID, subscription ID
- Databricks account ID, metastore ID, PAT token, SP credentials
- Per-layer: VM SKU, worker count, cron schedule, alert email
- JDBC source connection details (stored in Key Vault after apply)

### 2. Deploy Infrastructure with Terraform

```bash
cd infra/terraform
terraform init

# Create terraform.tfvars — names are auto-derived, only supply operational values
cat > terraform.tfvars << 'EOF'
azure_tenant_id                = "<TODO_AZURE_TENANT_ID>"
azure_subscription_id          = "<TODO_AZURE_SUBSCRIPTION_ID>"
azure_region                   = "uksouth"

workload                       = "<TODO_WORKLOAD>"    # e.g. "mdln" (4-6 chars)
environment                    = "<TODO_ENVIRONMENT>" # e.g. "prod"

databricks_account_id          = "<TODO_DATABRICKS_ACCOUNT_ID>"
databricks_metastore_id        = "<TODO_DATABRICKS_METASTORE_ID>"
databricks_workspace_pat_token = "<TODO_DATABRICKS_PAT_TOKEN>"
databricks_client_id           = "<TODO_DATABRICKS_CLIENT_ID>"
databricks_client_secret       = "<TODO_DATABRICKS_CLIENT_SECRET>"

databricks_secret_scope_name   = "medallion-secrets"

layers = {
  bronze = {
    job_cluster_node_type_id   = "Standard_D4s_v3"
    job_num_workers            = 2
    job_schedule_cron_schedule = "<TODO_BRONZE_CRON>"
    job_alert_email            = "<TODO_ALERT_EMAIL>"
  }
  silver = {
    job_cluster_node_type_id   = "Standard_D4s_v3"
    job_num_workers            = 2
    job_schedule_cron_schedule = "<TODO_SILVER_CRON>"
    job_alert_email            = "<TODO_ALERT_EMAIL>"
  }
  gold = {
    job_cluster_node_type_id   = "Standard_D4s_v3"
    job_num_workers            = 2
    job_schedule_cron_schedule = "<TODO_GOLD_CRON>"
    job_alert_email            = "<TODO_ALERT_EMAIL>"
  }
}

orchestrator_job = {
  job_cluster_node_type_id   = "Standard_D4s_v3"
  job_num_workers            = 1
  job_schedule_cron_schedule = "<TODO_ORCHESTRATOR_CRON>"
  job_alert_email            = "<TODO_ALERT_EMAIL>"
}
EOF

terraform validate
terraform apply -var-file=terraform.tfvars
terraform output -json  # copy outputs into databricks-bundle/databricks.yml
```

Terraform creates: resource group, 3× storage accounts, 3× access connectors, 3× Entra SPs, Key Vault, workspace, UC catalogs/schemas, storage credentials, external locations, RBAC grants.

### 3. Store Service Principal Secrets in Key Vault

After `terraform apply`, the output includes SP client IDs. Manually retrieve and store secrets:

```bash
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "bronze-client-secret" --value "<SP_SECRET>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "silver-client-secret" --value "<SP_SECRET>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "gold-client-secret" --value "<SP_SECRET>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "jdbc-connection-string" --value "<JDBC_URL>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "jdbc-username" --value "<USERNAME>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "jdbc-password" --value "<PASSWORD>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "source-table-name" --value "<TABLE>"
```

### 4. Deploy Databricks Bundle (DAB)

```bash
cd databricks-bundle

# Update databricks.yml: substitute all <TODO_*> values from Terraform output
databricks bundle validate
databricks bundle deploy
databricks bundle run orchestrator_job  # to test pipeline end-to-end
```

DAB creates: 4× Lakeflow jobs (Bronze, Silver, Gold, Orchestrator), 3× job clusters, job dependencies.

## Separation of Concerns

| Component | Owned By | Rationale |
|-----------|----------|-----------|
| Storage accounts, Access Connectors, Entra SPs, Key Vault | Terraform | Infrastructure; permanent resources; RBAC control |
| Databricks workspace, UC catalogs, schemas, storage credentials, external locations, grants | Terraform | Once created, rarely modified |
| Lakeflow jobs, job clusters, job schedules, clusters | DAB | Frequently updated; business logic |
| Python entrypoints (`src/*/main.py`) | DAB | Application code; version-controlled in bundle |

**Key rule:** Never define Terraform-managed resources in DAB. Never define jobs/notebooks in Terraform.

## Assumptions

- Pre-existing Databricks Account and Unity Catalog metastore
- Clean deployment (no inherited infrastructure)
- Region defaults to `uksouth` (see [Azure Regions](https://learn.microsoft.com/azure/reliability/regions-list))
- All secrets stored in Azure Key Vault; accessed via AKV-backed Databricks secret scope
- JDBC drivers pre-installed on cluster (or use Databricks cluster policies/libraries)

## Validation Checklist

- [ ] Azure resources visible in Portal (RG, storage, KV, workspace)
- [ ] Secrets stored in Key Vault (`az keyvault secret list --vault-name <KV>`)
- [ ] Workspace accessible via URL
- [ ] UC catalogs created (`show catalogs` in Databricks)
- [ ] SPs authenticated (try Bronze SP credentials)
- [ ] DAB jobs deployed (visible in Databricks Jobs UI)
- [ ] Run Bronze job end-to-end; verify raw data in UC table
- [ ] Verify Silver job reads Bronze only (cross-layer reads blocked)
- [ ] Verify Gold job reads Silver only
- [ ] No job failures in Databricks logs
- [ ] Enable Databricks system tables for audit per layer

## File Structure

```
.
├── SPEC.md                        # Architecture specification
├── TODO.md                        # Values to fill in before deploying
├── README.md                      # This file
├── infra/terraform/
│   ├── versions.tf               # Provider version locks
│   ├── providers.tf              # azurerm, azuread, databricks providers
│   ├── variables.tf              # Inputs (workload, environment + operational config)
│   ├── locals.tf                 # All resource names derived via CAF conventions
│   ├── main.tf                   # Resources: RG, storage, AC, SPs, KV, workspace, UC
│   ├── outputs.tf                # workspace_url, SP client IDs, catalog/schema names
│   └── terraform.tfvars          # (Create from TODO.md)
└── databricks-bundle/
    ├── databricks.yml            # Bundle config + DAB variables
    ├── resources/jobs.yml        # 4 Lakeflow jobs (bronze, silver, gold, orchestrator)
    └── src/
        ├── bronze/main.py        # JDBC ingest
        ├── silver/main.py        # Dedup + filter
        └── gold/main.py          # Groupby aggregation
```

## Troubleshooting

**Terraform apply fails (auth errors):**
- Verify `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- Check `databricks_account_id`, `databricks_client_id`
- Ensure PAT token is valid and not expired

**DAB validation fails:**
- Ensure all `<TODO_*>` values in `databricks.yml` are substituted
- Verify workspace URL and PAT token
- Check job cluster node types available in region

**Jobs fail to run:**
- Check SP secrets stored in Key Vault
- Verify SP has read/write access to storage accounts
- Check JDBC connection string and source database credentials
- Inspect job logs in Databricks UI

## Next Steps

1. **CI/CD:** Integrate Terraform + DAB into GitHub Actions / Azure DevOps
2. **Environments:** Replicate setup across dev/staging/prod with separate `terraform.tfvars`
3. **Monitoring:** Enable Databricks system tables, set up cost tracking per layer
4. **Data Quality:** Add schema validation, outlier detection in Silver/Gold
5. **Secrets Rotation:** Implement KV secret rotation policies

## References

- [Databricks Secure Medallion Architecture](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)
- [Databricks Declarative Automation Bundles](https://docs.databricks.com/en/dev-tools/bundles/index.html)
- [Unity Catalog Security](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [Azure Key Vault Integration](https://docs.databricks.com/en/security/secrets/secret-scopes.html)
- [Azure Regions](https://learn.microsoft.com/azure/reliability/regions-list)
