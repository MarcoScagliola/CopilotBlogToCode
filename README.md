# Deployment Guide: Secure Medallion Architecture on Azure Databricks

This repository contains infrastructure-as-code (Terraform + DAB) to deploy a production-ready **Secure Medallion Architecture** on Azure Databricks, following the Microsoft blog series "Secure Medallion Architecture Pattern on Azure Databricks."

**Source Article:** https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

---

## Architecture Overview

### What Gets Deployed

**Azure Infrastructure (Terraform):**
- Resource Group
- 3× ADLS Gen2 storage accounts (Bronze, Silver, Gold) with HNS enabled
- 3× Managed Identities (one per layer)
- 3× Databricks Access Connectors
- 3× Entra service principals
- Azure Key Vault with RBAC-enabled access
- Optional: VNet, subnets, NSG for network isolation

**Databricks and Unity Catalog Infrastructure (Terraform):**
- 1× Databricks workspace — **created by Terraform** (Premium SKU)
- 3× Unity Catalog storage credentials and external locations
- 3× UC catalogs (bronze_catalog, silver_catalog, gold_catalog)
- 3× UC schemas (per catalog)
- 4× Lakeflow jobs: Bronze, Silver, Gold, Orchestrator (chains the three sub-jobs)
- 3× Job clusters (per-layer compute with Photon optimization for Silver)

**Access Control:**
- Per-layer RBAC: each SP reads only its input and writes only its output
- UC grants enforce read-browse on upstream layers for downstream
- Secret scope backed by AKV for credential/API key management

---

## Prerequisites

1. **Azure Subscription & Tenant**: You must have:
   - Azure subscription ID
   - Microsoft Entra ID (Azure AD) tenant ID
   - Owner or Contributor role on the subscription

2. **Databricks Account**: You must have:
   - Databricks account ID (from account console)
   - Active Databricks workspace (URL and admin token)
   - Account-level admin permissions for service principal registration

3. **Local Tools**:
   - Terraform CLI (≥ 1.5)
   - Azure CLI (`az`) or sufficient Azure permissions to authenticate
   - Python 3.9+ (for DAB validation)
   - Databricks CLI (`databricks` CLI v0.20+)

4. **Permissions**:
   - Terraform will create Azure resources; ensure your CLI session has sufficient permissions
   - Databricks DAB will create jobs, clusters, catalogs; ensure workspace PAT or OAuth token has admin scope

---

## Quick Start

### 1. Fill TODO Values

Edit `TODO.md` with actual values from your Azure and Databricks environments:

**Terraform inputs (set in `terraform.tfvars`):**
- `azure_subscription_id` — your Azure subscription GUID
- `azure_tenant_id` — your Entra ID tenant GUID
- `databricks_account_id` — from Databricks account console
- `databricks_metastore_id` — from Databricks account console → Data → Metastores

> `azure_region`, `environment`, `project_prefix`, `secret_scope_name` all have sensible defaults.

**Terraform outputs (populate DAB variables after `terraform apply`):**
- `databricks_workspace_url` → set as `host` in `databricks-bundle/databricks.yml`
- `service_principal_client_ids["bronze/silver/gold"]` → set as SP client ID variables in the bundle
- `unity_catalog_names["bronze/silver/gold"]` → set as catalog name variables in the bundle

**DAB variables:**
- Job schedules (cron expressions) — see `databricks-bundle/resources/jobs.yml`
- Alert email — see `var.alert_email` in `databricks-bundle/databricks.yml`

### 2. Create `terraform.tfvars`

Copy values from `TODO.md` into `infra/terraform/terraform.tfvars`:

```hcl
# infra/terraform/terraform.tfvars
azure_subscription_id   = "<TODO: your Azure subscription GUID>"
azure_tenant_id         = "<TODO: your Entra ID tenant GUID>"
azure_region            = "uksouth"       # default; override if required
environment             = "prod"          # dev / test / prod
project_prefix          = "medallion"
databricks_account_id   = "<TODO: Databricks account UUID>"
databricks_metastore_id = "<TODO: Unity Catalog metastore UUID>"
# secret_scope_name defaults to "akv-scope" — override if required
```

### 3. Authenticate to Azure & Databricks

```bash
# Authenticate to Azure
az login --tenant <your-tenant-id>
az account set --subscription <your-subscription-id>

# Test Databricks connectivity
databricks workspace list
```

### 4. Validate & Deploy Terraform

```bash
cd infra/terraform

# Format and validate
terraform fmt -recursive
terraform validate

# Plan
terraform plan -out=tfplan

# Review the plan, then apply
terraform apply tfplan
```

**Output:** Terraform will output resource IDs, storage account names, identity IDs. Save these for DAB configuration.

### 5. AKV-Backed Secret Scope (Terraform-managed)

The AKV-backed secret scope is **created automatically by Terraform** using the `databricks_secret_scope` resource. No manual step is needed.

After `terraform apply`, verify it exists:

```bash
databricks secrets list-scopes
```

Expected output: a scope named `akv-scope` (or your `var.secret_scope_name` value) backed by the Key Vault deployed in this stack.

### 6. Create Bundle Variables File

Create `databricks-bundle/override.yml`:

```yaml
variables:
  databricks_workspace_url: "https://adb-xxxxx.azuredatabricks.net"
  run_as_user: "<your-workspace-user-email>"
  bronze_sp_app_id: "<bronze-sp-app-id>"
  silver_sp_app_id: "<silver-sp-app-id>"
  gold_sp_app_id: "<gold-sp-app-id>"
  bronze_job_name: "medallion-bronze-job"
  silver_job_name: "medallion-silver-job"
  gold_job_name: "medallion-gold-job"
  orchestrator_job_name: "medallion-orchestrator"
  bronze_schedule: "0 2 * * *"  # 2 AM UTC daily
  silver_schedule: "0 4 * * *"
  gold_schedule: "0 6 * * *"
  orchestrator_schedule: "0 1 * * *"  # 1 AM UTC daily (kicks off chain)
  alert_email: "data-ops@company.com"
  timezone: "UTC"
  bronze_catalog: "bronze_catalog"
  bronze_schema: "bronze_schema"
  silver_catalog: "silver_catalog"
  silver_schema: "silver_schema"
  gold_catalog: "gold_catalog"
  gold_schema: "gold_schema"
  secret_scope_name: "kv-medallion"
  # ... cluster and node type configs
```

### 7. Validate & Deploy DAB

```bash
cd databricks-bundle

# Validate bundle
databricks bundle validate -t dev

# Deploy to dev workspace
databricks bundle deploy -t dev

# View deployed jobs
databricks bundle summary -t dev
```

### 8. Test End-to-End

```bash
# Run the orchestrator job (this kicks off Bronze → Silver → Gold chain)
databricks bundle run orchestrator_job -t dev

# Monitor in Databricks workspace UI:
# Workflows > medallion-orchestrator_job > view run
```

---

## Separation of Concerns

### What Terraform Manages

✅ Azure Resource Group
✅ Storage accounts (ADLS Gen2), containers
✅ Managed Identities
✅ Entra app registrations & service principals
✅ Key Vault & RBAC
✅ Databricks Access Connectors
✅ UC storage credentials, external locations, catalogs, schemas
✅ RBAC grants (READ BROWSE on upstream → downstream)
✅ Networking (VNet, subnets, NSG)

✅ Databricks workspace (Premium SKU — created by Terraform)
❌ Jobs/clusters (managed by DAB)
❌ Notebooks/scripts (managed by DAB)

### What DAB Manages

✅ Lakeflow jobs (Bronze, Silver, Gold, Orchestrator)
✅ Job cluster definitions (per-layer compute)
✅ Job parameters and scheduling
✅ Notifications and run-as identities
✅ Entrypoint Python code `src/main.py`

❌ Storage accounts, identities, Key Vault (managed by Terraform)
❌ UC catalogs/schemas (managed by Terraform)

This strict separation ensures:
- **No duplication**: each component defined once
- **Clear ownership**: infrastructure vs. jobs/code
- **Easy updates**: modify jobs without re-provisioning cloud resources

---

## Assumptions & Known Limitations

1. **Databricks Workspace Created by Terraform**: The workspace is provisioned as a Premium-tier resource. Terraform assigns the pre-existing Unity Catalog metastore to it via `databricks_metastore_assignment`.

2. **Secret Scope Created by Terraform**: The AKV-backed secret scope is provisioned via `databricks_secret_scope`. No manual creation step is required.

3. **Single Workspace**: Deployment targets one workspace. For multi-workspace, replicate DAB deployment per workspace.

4. **Service Principal Authentication**: Jobs run as Entra SPs; each SP must be registered with Databricks account. The blog assumes this is done pre-deployment.

5. **Network Isolation**: VNet/NSG are optional. If disabled, Databricks clusters still use VNET + VNet endpoint security by default in workspace-managed VNet mode.

6. **Cluster Reusability**: Each job gets its own cluster (job cluster mode). This is simpler but less cost-optimized. Future iterations could use all-purpose clusters + cluster policies.

---

## Cost Optimization Tips

1. **Auto-terminate clusters**: Jobs automatically spin down clusters post-job. No idling cost.
2. **Right-size node types**: Bronze can use cheaper SKUs (D4s); Gold needs more for analytics. Adjust `node_type` per layer.
3. **Autoscaling**: Each job cluster autoscales 1→3 (Bronze), 1→5 (Silver), 1→4 (Gold) workers. Tune `max_workers` based on data volume.
4. **Schedule off-peak**: Jobs run at 2 AM, 4 AM, 6 AM UTC; adjust if your business peak differs.
5. **Monitor spend**: Enable Databricks billing tables and query `system.billing.*` to track cost per layer.

---

## Monitoring & Observability

### Enable System Tables

In Databricks workspace:

```sql
-- Grant access to system tables (requires admin)
GRANT USAGE ON CATALOG system TO `<principal>`;

-- Query job runs
SELECT * FROM system.lakeflow.jobs;
SELECT * FROM system.lakeflow.runs WHERE job_id = <job_id>;
SELECT * FROM system.lakeflow.tasks WHERE run_id = <run_id>;

-- Billing by layer
SELECT
  billable_usage_month,
  workspace_id,
  sku_name,
  usage,
  (usage * unit_price) as cost
FROM system.billing.billable_usage
WHERE sku_name LIKE '%DBU%'
ORDER BY cost DESC;
```

### Jobs UI

Navigate to **Workflows** → **medallion-orchestrator** to:
- View run history and timelines
- Drill into task logs (Bronze, Silver, Gold)
- Set up alerts for job failures

---

## Troubleshooting

### Authentication Errors

```
Error: Error acquiring the state lock: 409 Conflict

→ Solution: Another Terraform apply is in progress. Wait or manually unlock:
  terraform force-unlock <lock-id>
```

### Storage Account Name Conflicts

```
Error: Name already in use

→ Solution: Storage account names are globally unique. Choose a different name prefix.
```

### Job Execution Failures

**Bronze job fails to read external source:**
- Check secret scope contains API key: `databricks secrets list-scopes`
- Verify Secret Vault permissions (RBAC on Key Vault)
- Check managed identity can access external source (network/firewall rules)

**Silver job can't read Bronze:**
- Verify Bronze catalog is readable: `SHOW GRANTS ON CATALOG bronze_catalog;`
- Confirm Silver SP has READ BROWSE: should show permission from Terraform grant

**Gold job writes fail:**
- Check Gold security group has WRITE: `SHOW GRANTS ON EXTERNAL_location gold_location;`
- Verify storage account role assignment: `az role assignment list --scope <storage-id>`

---

## Cleanup

To tear down all resources:

```bash
# Remove DAB deployment
databricks bundle destroy -t dev

# Destroy Terraform
cd infra/terraform
terraform destroy
```

**Warning:** This will delete:
- All storage accounts and data
- Key Vault and secrets
- Catalogs and schemas
- Jobs and clusters

Ensure you backup critical data before running `terraform destroy`.

---

## Next Steps

1. **Implement layer logic** in `databricks-bundle/src/main.py`:
   - Bronze: Add your data ingestion (APIs, DB, files)
   - Silver: Add transformation and cleansing logic
   - Gold: Add analytics and dimensional model logic

2. **Add CI/CD** (Part II topic):
   - GitHub Actions → plan/apply Terraform
   - Run DAB validation and deployment
   - Trigger test run of orchestrator job

3. **Optimize performance**:
   - Use `CLUSTER BY AUTO` for frequently filtered columns (Managed tables, DBR 15.4+)
   - Enable Predictive Optimization
   - Monitor query performance in Gold schema

4. **Expand governance**:
   - Enable system tables for cost/performance analytics
   - Set up data quality checks (e.g., schema validation on Bronze)
   - Implement change data capture (CDC) for Silver incremental updates

---

## Support & References

- **Blog**: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- **Terraform Docs**: https://registry.terraform.io/providers/databricks/databricks/latest/docs
- **DBX Bundle Docs**: https://docs.databricks.com/en/dev-tools/bundles/
- **Unity Catalog**: https://docs.databricks.com/en/data-governance/unity-catalog/
- **Lakeflow Jobs**: https://docs.databricks.com/en/workflows/

---

**Deployment Complete!** 🎉

Your secure medallion architecture is ready for data ingestion, transformation, and curation with enterprise-grade isolation, governance, and auditability.

### 3. Deploy Terraform

```bash
cd infra/terraform
# Fill in terraform.tfvars with your subscription, region, workspace URL, etc.
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

### 4. Deploy DAB

```bash
cd databricks-bundle
# Set variables (workspace_url, SP IDs, secret scope) via --var flags or databricks.yml
databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run <job_name> -t dev
```

## Error codes (fetch_blog.py)

| Code | Meaning |
|------|---------|
| `USAGE` | Wrong number of arguments |
| `INVALID_URL` | URL doesn't start with `http://` or `https://` |
| `HTTP_<status>` | Server returned an HTTP error (e.g. `HTTP_404`) |
| `URL_ERROR` | DNS failure or host unreachable |
| `TIMEOUT` | No response within 30 seconds |
| `PARSE_ERROR` | HTML parsing failed |
| `EMPTY_CONTENT` | Page returned no extractable content |
