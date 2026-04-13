# Secure Medallion Architecture on Azure Databricks

A production-ready infrastructure-as-code (IaC) implementation of the **secure medallion architecture pattern** (Bronze → Silver → Gold) on Azure Databricks, with Unity Catalog governance and least-privilege service principals.

**Source Architecture:** [Secure Medallion Architecture Pattern on Azure Databricks, Part I](https://techcommunity.microsoft.com/blog/analyticsonaxure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

---

## Quick Start

### Prerequisites

1. **Azure Account**
   - Subscription with sufficient quota (VMs, storage, Databricks)
   - Entra ID tenant access (to create service principals)
   - Resource Group created or permissions to create one

2. **Databricks Account**
   - Databricks account ID (from [accounts.cloud.databricks.com](https://accounts.cloud.databricks.com))
   - Metastore created and ready for workspace assignment
   - OAuth client credentials (service principal) for Terraform auth

3. **JDBC Source Database**
   - Hostname, database name, username, password
   - Network connectivity from Databricks workspace (JDBC driver)
   - Source table name(s) to ingest

4. **Local Tools**
   - Terraform CLI (>= 1.5)
   - Databricks CLI (`databricks --version`)
   - Azure CLI (`az --version`)
   - Python 3.9+

5. **GitHub Actions (optional)**
   - GitHub environment `BLG2CODEDEV` with secrets:
     - `AZURE_TENANT_ID`
     - `AZURE_SUBSCRIPTION_ID`
     - `DATABRICKS_ACCOUNT_ID`
     - `DATABRICKS_CLIENT_ID`
     - `DATABRICKS_CLIENT_SECRET`

---

## Deployment Steps

### Phase 1: Prepare Variables

1. **Collect Required Values** (see [TODO.md](TODO.md) for full list)
   ```bash
   # Azure
   AZURE_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   
   # Databricks
   DATABRICKS_ACCOUNT_ID="123456789012345"
   DATABRICKS_METASTORE_ID="metastore-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   DATABRICKS_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   DATABRICKS_CLIENT_SECRET="<oauth-secret>"
   
   # JDBC Source Database
   JDBC_HOST="source-db.region.cloudapp.azure.com"
   JDBC_DATABASE="prod_db"
   JDBC_USER="sa_user"
   JDBC_PASSWORD="<password>"
   ```

2. **Create `terraform.tfvars`**
   ```bash
   cat > infra/terraform/terraform.tfvars << EOF
   azure_tenant_id              = "$AZURE_TENANT_ID"
   azure_subscription_id        = "$AZURE_SUBSCRIPTION_ID"
   databricks_account_id        = "$DATABRICKS_ACCOUNT_ID"
   databricks_metastore_id      = "$DATABRICKS_METASTORE_ID"
   databricks_client_id         = "$DATABRICKS_CLIENT_ID"
   databricks_client_secret     = "$DATABRICKS_CLIENT_SECRET"
   
   jdbc_host                    = "$JDBC_HOST"
   jdbc_database                = "$JDBC_DATABASE"
   jdbc_user                    = "$JDBC_USER"
   jdbc_password                = "$JDBC_PASSWORD"
   
   # Optional overrides (defaults: workload=blg, environment=dev, region=uksouth)
   workload    = "blg"
   environment = "dev"
   azure_region = "uksouth"
   EOF
   ```

3. **Secure `terraform.tfvars`**
   ```bash
   # Add to .gitignore (CRITICAL: Never commit)
   echo "infra/terraform/terraform.tfvars" >> .gitignore
   ```

---

### Phase 2: Terraform – Infrastructure & Unity Catalog

1. **Initialize Terraform**
   ```bash
   cd infra/terraform
   terraform init
   ```

2. **Validate Configuration**
   ```bash
   terraform validate
   terraform fmt -check  # Check formatting
   terraform plan -out=tfplan  # Review changes
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform apply tfplan
   ```
   
   This creates:
   - Resource Group, 3 storage accounts (Bronze/Silver/Gold)
   - Azure Key Vault with JDBC secrets
   - 3 service principals (Entra ID) with RBAC assignments
   - 3 Databricks access connectors (managed identities)
   - Databricks workspace with Unity Catalog enabled
   - UC catalogs, schemas, storage credentials, external locations

4. **Capture Terraform Outputs**
   ```bash
   terraform output -json > ../outputs.json
   WORKSPACE_URL=$(terraform output -raw databricks_workspace_url)
   BRONZE_SP=$(terraform output -raw bronze_sp_client_id)
   SILVER_SP=$(terraform output -raw silver_sp_client_id)
   GOLD_SP=$(terraform output -raw gold_sp_client_id)
   SECRET_SCOPE=$(terraform output -raw secret_scope_name)
   ```

---

### Phase 3: Databricks Asset Bundle – Jobs & Notebooks

1. **Update DAB Variables**
   ```bash
   cd ../.. && cd databricks-bundle
   
   # Update databricks.yml with Terraform outputs
   cat >> databricks.yml << EOF
   
   # (Append to variables section)
   workspace_host: "$WORKSPACE_URL"
   bronze_sp_client_id: "$BRONZE_SP"
   silver_sp_client_id: "$SILVER_SP"
   gold_sp_client_id: "$GOLD_SP"
   secret_scope: "$SECRET_SCOPE"
   source_table_name: "sales_transactions"  # Change to your source table
   alert_email: "ops-team@company.com"      # Change to your email
   EOF
   ```

2. **Validate Bundle**
   ```bash
   databricks bundle validate
   ```

3. **Deploy Jobs & Notebooks**
   ```bash
   # Deploy to dev target
   databricks bundle deploy --target dev
   
   # Or to prod (requires different backend/catalog settings)
   # databricks bundle deploy --target prod
   ```

4. **Verify Jobs Created**
   ```bash
   databricks jobs list --output json | jq '.jobs[] | {name: .settings.name, job_id: .job_id}'
   ```

---

### Phase 4: Run Pipeline

#### Option A: Manual Trigger (via CLI)
```bash
# Run orchestrator job (chains Bronze → Silver → Gold → Checkpoint)
ORCHESTRATOR_JOB_ID=$(databricks jobs list --output json | jq '.jobs[] | select(.settings.name == "blg-orchestrator") | .job_id')

databricks jobs run-now --job-id $ORCHESTRATOR_JOB_ID
```

#### Option B: Schedule via Databricks UI
1. Navigate to `Workflows` → Jobs → `blg-orchestrator`
2. Click **Schedule** and set cron (e.g., `0 8 * * MON-FRI` for 8 AM weekdays)
3. Toggle **Pause status** to `UNPAUSED`

#### Option C: GitHub Actions (CI/CD)
Uncomment the GitHub Actions workflows in `.github/workflows/` to auto-deploy on PR merge.

---

## Architecture Overview

### Azure Resources
- **RG:** `rg-blg-dev-uks`
- **Storage Accounts:**
  - `stblgbrzdev` (Bronze, raw data)
  - `stblgslvdev` (Silver, curated data)
  - `stblgglddev` (Gold, aggregated analytics)
- **Key Vault:** `kv-blg-dev-uks` (JDBC credentials)
- **Service Principals:** `sp-blg-{bronze|silver|gold}-dev-uks`
- **Databricks Workspace:** `dbw-blg-dev-uks`
- **Access Connectors:** `dbac-blg-{brz|slv|gld}-dev-uks`

### Databricks Resources
- **Workspace:** Unity Catalog enabled, metastore assigned
- **Catalogs:**
  - `blg_bronze.raw_data` (managed tables)
  - `blg_silver.curated_data` (managed tables)
  - `blg_gold.analytics` (managed tables)
- **Jobs:**
  - `blg-bronze-ingest` (JDBC source → Bronze)
  - `blg-silver-transform` (Bronze → Silver, dedup/filter)
  - `blg-gold-aggregate` (Silver → Gold, GROUP BY aggregation)
  - `blg-orchestrator` (chains jobs, checkpoint)
- **Secret Scope:** `blg-dev-uks-akv` (AKV-backed, JDBC credentials)

### Data Flow
```
[JDBC Source Database]
        ↓
[Bronze: stblgbrzdev / blg_bronze.raw_data]
        ↓
[Silver: stblgslvdev / blg_silver.curated_data]
        ↓
[Gold: stblgglddev / blg_gold.analytics]
        ↓
[Checkpoint Table: _pipeline_checkpoint]
```

---

## Configuration

### Terraform Variables (infra/terraform/variables.tf)

| Variable | Type | Required | Description |
|---|---|---|---|
| `azure_tenant_id` | string | Yes | Entra ID tenant ID |
| `azure_subscription_id` | string | Yes | Azure subscription ID |
| `databricks_account_id` | string | Yes | Databricks account ID (15-digit) |
| `databricks_metastore_id` | string | Yes | Metastore ID (metastore-UUID) |
| `databricks_client_id` | string | Yes | OAuth client ID (service principal) |
| `databricks_client_secret` | string | Yes | OAuth client secret |
| `jdbc_host` | string | Yes | JDBC source hostname |
| `jdbc_database` | string | Yes | Source database name |
| `jdbc_user` | string | Yes | Source DB username |
| `jdbc_password` | string | Yes | Source DB password |
| `workload` | string | No | Workload name (default: blg) |
| `environment` | string | No | Environment (dev/prod, default: dev) |
| `azure_region` | string | No | Azure region (default: uksouth) |

### DAB Variables (databricks-bundle/databricks.yml)

All DAB variables have defaults and can be overridden via:
- `databricks.yml` file
- CLI: `databricks bundle deploy -v var.source_table_name=my_table`
- Environment: `DATABRICKS_VAR_SOURCE_TABLE_NAME=my_table`

---

## Troubleshooting

### Terraform Issues

**Error: "Provider configuration missing"**
- Ensure `terraform.tfvars` is created and contains all required variables
- Run: `terraform validate`

**Error: "resource already exists"**
- Resource group or workspace may already exist
- Run: `terraform import` to adopt existing resources, or remove manually and re-apply

**Error: "Access Connector failed to create"**
- Ensure Databricks workspace creation completed first
- Check Azure permissions for Databricks resource provider

### Databricks Issues

**DAB Validation Fails**
- Ensure `workspace_host` is set correctly (from Terraform output)
- Run: `databricks bundle validate` with verbose: `databricks bundle validate --debug`

**Job Fails: "Table not found"**
- Verify Unity Catalog and schemas were created by Terraform
- Check Databricks workspace URL is correct
- Run SQL: `SHOW CATALOGS; SHOW SCHEMAS IN blg_bronze;`

**JDBC Connection Error**
- Verify JDBC host/database/user/password in Key Vault
- Test connectivity from Databricks workspace: `curl -v jdbc_host:port`
- Ensure JDBC driver is available (SQL Server, PostgreSQL, MySQL, etc.)

### Access & Permissions

**Error: "Storage credential not found"**
- Verify access connectors were created and have system-assigned managed identities
- Check RBAC assignments: SP → Storage account

**Error: "Secret not accessible"**
- Verify secret scope is AKV-backed and Key Vault has secrets defined
- Check Databricks cluster has permission to read from AKV
- Test: `dbutils.secrets.list(scope="blg-dev-uks-akv")`

---

## File Structure

```
.
├── README.md                     # This file
├── SPEC.md                       # Architecture specification
├── TODO.md                       # Unresolved values checklist
├── infra/
│   └── terraform/
│       ├── versions.tf           # Provider version constraints
│       ├── providers.tf          # Provider authentication
│       ├── variables.tf          # Input variables (with validation)
│       ├── locals.tf             # Derived naming (CAF-aligned)
│       ├── main.tf              # Infrastructure resources (RG, KV, storage, UC)
│       └── outputs.tf           # Terraform outputs (handoff to DAB)
├── databricks-bundle/
│   ├── databricks.yml           # DAB config, variables, targets
│   ├── resources/
│   │   └── jobs.yml            # Job definitions (Bronze, Silver, Gold, Orchestrator)
│   └── src/
│       ├── bronze/
│       │   └── main.py         # JDBC ingest notebook
│       ├── silver/
│       │   └── main.py         # Transform & dedup notebook
│       ├── gold/
│       │   └── main.py         # Aggregate notebook
│       └── orchestrator/
│           └── main.py         # Checkpoint & monitoring notebook
└── .github/
    └── workflows/               # (Optional) CI/CD pipelines
        ├── validate-terraform.yml
        └── deploy-infrastructure.yml
```

---

## Naming Conventions

All resource names follow [Cloud Adoption Framework (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging) standards, computed in `locals.tf`:

- **Pattern:** `{type}-{workload}-{component}-{environment}-{region_abbr}`
- **Example:** `rg-blg-dev-uks`, `sp-blg-bronze-dev-uks`, `dbw-blg-dev-uks`
- **Override:** Modify `locals.tf` or `variables.tf` to customize

---

## Security Best Practices

1. **Service Principal Isolation**
   - Each layer (Bronze, Silver, Gold) has its own service principal
   - SPs are scoped to their respective storage accounts (least privilege)
   - SPs authenticate via Databricks access connectors (managed identity)

2. **Secret Management**
   - JDBC credentials stored in Azure Key Vault
   - AKV-backed Databricks secret scope (not plaintext)
   - Secrets rotated outside of Terraform (manual or via Azure Policy)

3. **Data Governance**
   - Unity Catalog enforces schema-level access control
   - Managed tables only (no external tables by design)
   - All data stays in customer-managed storage (ADLS Gen2)

4. **Network Security** (optional enhancements)
   - Private endpoints for Key Vault
   - Network security groups (NSGs) for storage accounts
   - Databricks workspace with private link (premium SKU)

---

## Costs

Estimated monthly cost (USD, approximate):
- **Databricks Workspace (Premium):** ~$2,000/month (varies by cluster usage)
- **Storage Accounts (3x LRS):** ~$30/month
- **Key Vault:** ~$0.33/month
- **Data Transfer:** ~$0 (intra-region)

See [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for region-specific rates.

---

## Support & Documentation

- [Databricks Documentation](https://docs.databricks.com/)
- [Unity Catalog Guide](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [Azure Databricks Best Practices](https://learn.microsoft.com/en-us/azure/databricks/best-practices/)
- [Terraform Databricks Provider](https://registry.terraform.io/providers/databricks/databricks/latest)
- [Databricks Asset Bundles (DAB)](https://docs.databricks.com/en/dev-tools/bundles/index.html)

---

## License

This IaC template is provided as-is under the MIT License.

---

## Next Steps

1. ✅ Review [SPEC.md](SPEC.md) for architecture details
2. ✅ Fill all values in [TODO.md](TODO.md)
3. 🚀 Deploy Terraform infrastructure
4. 🚀 Deploy DAB jobs and notebooks
5. 📊 Monitor pipeline execution and adjust transformation logic as needed
6. 📈 Set up alerting and cost monitoring

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

Configure these repository-level GitHub secrets for deployment:

- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `DATABRICKS_TOKEN`
- `DATABRICKS_ACCOUNT_ID`
- `DATABRICKS_METASTORE_ID`
- `JDBC_HOST`
- `JDBC_DATABASE`
- `JDBC_USER`
- `JDBC_PASSWORD`

Set them with GitHub CLI (example):

```bash
gh secret set AZURE_CLIENT_ID --body "<your-client-id>"
gh secret set AZURE_CLIENT_SECRET --body "<your-client-secret>"
gh secret set DATABRICKS_TOKEN --body "<your-databricks-token>"
```

Or in GitHub UI:

1. Open `Settings` > `Secrets and variables` > `Actions`.
2. Create the secrets listed above.

This repo includes:

- `.github/workflows/validate-terraform.yml` (manual validation)
- `.github/workflows/deploy.yml` (terraform apply -> outputs -> DAB deploy)

`azure_tenant_id` and `azure_subscription_id` are passed as required `workflow_dispatch` inputs when you run either workflow.
