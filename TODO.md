# Unresolved Values – Secure Medallion On Azure Databricks (Dev)

**Generated:** April 13, 2026  
**Environment:** dev (uksouth)  
**Status:** Ready for user input before Terraform plan

---

## Critical Azure Values (Required for Terraform)

### Tenant & Subscription (Global Azure Context)
- [ ] `AZURE_TENANT_ID`: Microsoft Entra ID tenant ID (UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  - **Where:** GitHub environment secret `AZURE_TENANT_ID` or `terraform.tfvars`
  - **Used by:** Terraform provider `azurerm` and `azuread`

- [ ] `AZURE_SUBSCRIPTION_ID`: Azure subscription ID (UUID format)
  - **Where:** GitHub environment secret `AZURE_SUBSCRIPTION_ID` or `terraform.tfvars`
  - **Used by:** All Azure resources (RG, storage, KV, workspace)

---

## Databricks Values (Required for Terraform & DAB)

### Account-Level
- [ ] `DATABRICKS_ACCOUNT_ID`: Databricks account ID (numeric, e.g., 123456789012345)
  - **Where:** `infra/terraform/terraform.tfvars` or environment variable
  - **Used by:** Account-level provider for workspace creation

- [ ] `DATABRICKS_METASTORE_ID`: Metastore ID (formatted as metastore-UUID)
  - **Where:** `infra/terraform/terraform.tfvars`
  - **Used by:** Unity Catalog metastore assignment to workspace
  - **Note:** Requires pre-creation via Databricks account console

### Workspace-Level Authentication
- [ ] `DATABRICKS_HOST`: Workspace URL (e.g., https://adb-xxxxxxxxxxxx.xx.azuredatabricks.net)
  - **Source:** Terraform output after workspace creation (`databricks_workspace_url`)
  - **Used by:** DAB deployment and Databricks CLI

- [ ] `DATABRICKS_TOKEN` or Entra ID authentication
  - **Where:** GitHub environment secret or local .databrickscfg
  - **Used by:** Terraform provider (workspace-level) and DAB CLI

---

## JDBC Source Database (Required for Bronze Job)

- [ ] `jdbc_host`: Database hostname or IP (e.g., source-db.eastus.cloudapp.azure.com)
  - **Where:** Key Vault secret `jdbc_host` (created by Terraform)
  - **Used by:** Bronze ingest job (jaydebeapi/sqlalchemy read)

- [ ] `jdbc_database`: Database name (e.g., prod_db, analytics_db)
  - **Where:** Key Vault secret `jdbc_database`
  - **Used by:** Bronze ingest connection string

- [ ] `jdbc_user`: Database username
  - **Where:** Key Vault secret `jdbc_user`
  - **Used by:** Bronze ingest authentication

- [ ] `jdbc_password`: Database password
  - **Where:** Key Vault secret `jdbc_password`
  - **Used by:** Bronze ingest authentication
  - **Note:** Marked as sensitive in Terraform; do not commit to Git

- [ ] `source_table_name`: Source table name (e.g., sales_transactions, user_events)
  - **Where:** DAB variable `source_table_name` in `databricks-bundle/databricks.yml`
  - **Used by:** Bronze ingest notebook to parameterize source query

---

## Operational (Required for Job Alerts)

- [ ] `alert_email`: Email address for job failure notifications
  - **Where:** DAB variable `alert_email` in resources/jobs.yml
  - **Used by:** Databricks job configuration, notification task (if implemented)
  - **Format:** Valid email (e.g., analytics-team@company.com)

---

## Optional Customizations (Not Critical)

- [ ] **Slack webhook URL** (for job notifications): If integrating with Slack instead of email
  - **Where:** Key Vault secret `slack_webhook_url`
  - **Used by:** Orchestrator job error handler

- [ ] **Job schedule** (cron): Override default no-schedule behavior
  - **Where:** `databricks-bundle/resources/jobs.yml` field `schedule`
  - **Default:** No schedule (manual trigger only)

- [ ] **Cluster configuration** (worker count, node type): Custom Databricks cluster settings
  - **Where:** `databricks-bundle/resources/jobs.yml` field `new_cluster`
  - **Default:** Single-node cluster (singleNode profile)

- [ ] **Storage container names**: If different from defaults (raw, curated, analytics)
  - **Where:** Storage account blob containers (set during Terraform main.tf)
  - **Default:** `raw`, `curated`, `analytics`

---

## Checklist: How to Fill Unresolved Values

### 1. Before Terraform Plan
```bash
# Set up environment variables or terraform.tfvars
export AZURE_TENANT_ID="<your-tenant-id>"
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
export DATABRICKS_ACCOUNT_ID="<your-account-id>"

# Create terraform.tfvars or use environment:
cat > infra/terraform/terraform.tfvars << EOF
azure_tenant_id = "<your-tenant-id>"
azure_subscription_id = "<your-subscription-id>"
databricks_account_id = "<your-account-id>"
databricks_metastore_id = "metastore-<uuid>"
jdbc_host = "<your-source-db.host>"
jdbc_database = "<database-name>"
jdbc_user = "<db-user>"
jdbc_password = "<db-password>"
EOF
```

### 2. After Terraform Apply
```bash
# Extract Databricks workspace URL and populate DAB
WORKSPACE_URL=$(terraform -chdir=infra/terraform output -raw databricks_workspace_url)

# Update databricks-bundle/databricks.yml:
sed -i "s|<workspace-url>|$WORKSPACE_URL|g" databricks-bundle/databricks.yml
```

### 3. Before DAB Deploy
```bash
# Populate source table name and alert email
# Edit databricks-bundle/databricks.yml:
variables:
  source_table_name: "<your-source-table>"
  alert_email: "<your-email@company.com>"

# Deploy DAB
cd databricks-bundle && databricks bundle deploy
```

---

## Sensitive Values & Security Notes

- **NEVER** commit `terraform.tfvars` or secrets to Git
- **DO** store JSON values as GitHub environment secrets for CI/CD
- **DO** rotate JDBC credentials periodically
- **DO** enable Azure Key Vault audit logging for secret access

---

## Verification Steps

Once all values are filled, run:

```bash
# Terraform validation
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan -out=tfplan

# DAB validation
cd databricks-bundle && databricks bundle validate

# Pre-deployment checks
# (Run before 'terraform apply' and 'databricks bundle deploy')
```

---

## Next Steps

1. **Fill all Critical Azure and Databricks values** (see sections above)
2. **Run Terraform plan** to validate resource definitions
3. **Run Terraform apply** to create Azure resources and UC metadata
4. **Capture Terraform outputs** and inject into DAB
5. **Deploy DAB** to create jobs and notebooks
6. **Monitor first job run** and adjust JDBC credentials or transformation logic as needed
