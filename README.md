## Secure Medallion Architecture on Azure Databricks

This repository implements the Part I blog architecture for a security-first medallion pattern on Azure Databricks. The solution provisions Azure infrastructure with Terraform, deploys Lakeflow jobs through a Databricks Asset Bundle, and keeps per-layer identities, storage accounts, and access connectors separated across Bronze, Silver, and Gold.

### What is included

- `infra/terraform/`: Azure resource group, Databricks workspace, ADLS Gen2 storage accounts, Access Connectors, Key Vault, and optional per-layer Microsoft Entra service principals.
- `databricks-bundle/`: bundle definition, generated jobs, and Python entrypoints for setup, Bronze, Silver, Gold, and smoke-test jobs.
- `.github/workflows/`: generated validation, infrastructure deployment, and DAB deployment workflows.
- `SPEC.md`: architecture notes captured from the source article.
- `TODO.md`: follow-up manual tasks and production hardening items.

### Architecture summary

- One storage account per medallion layer.
- One Databricks Access Connector per layer for least-privilege storage access.
- One logical execution identity per layer.
- One orchestration job that runs setup, Bronze, Silver, Gold, then smoke test.
- Azure Key Vault used as the runtime secret source for external-system credentials.
- Unity Catalog managed tables used for the sample Bronze, Silver, and Gold datasets.

### Defaults used by this repo

- Workload: `blg`
- Environment: `dev`
- Region: `uksouth`
- GitHub environment: `BLG2CODEDEV`
- Layer principal mode: `create`

### Prerequisites

- Terraform 1.8+
- Python 3.11+
- Azure CLI authenticated with permissions to deploy Azure resources
- Databricks CLI available for bundle deployment
- GitHub environment secrets or variables:
	- `AZURE_TENANT_ID`
	- `AZURE_SUBSCRIPTION_ID`
	- `AZURE_CLIENT_ID`
	- `AZURE_CLIENT_SECRET`
	- `AZURE_SP_OBJECT_ID`
- Optional for `layer_sp_mode=existing`:
	- `EXISTING_LAYER_SP_CLIENT_ID`
	- `EXISTING_LAYER_SP_OBJECT_ID`

### Deployment flow

1. Run `Validate Terraform` to catch syntax drift.
2. Run `Deploy Infrastructure` with your target, workload, environment, region, and principal mode.
3. After Terraform succeeds, complete the manual steps in `TODO.md`:
	 - create the AKV-backed Databricks secret scope
	 - populate runtime secrets such as `source-system-token`
	 - grant any remaining Unity Catalog privileges
4. Run `Deploy DAB` against the infrastructure run ID.
5. Trigger the `orchestrator_job` in Databricks.

### Local validation

```powershell
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py
Get-ChildItem databricks-bundle/src -Recurse -Filter main.py | ForEach-Object { python -m py_compile $_.FullName }
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
& 'C:\Program Files\Git\bin\bash.exe' .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
```

### Runtime behavior

The sample jobs are intentionally small but complete:

- `setup`: creates catalogs and schemas if they do not already exist.
- `bronze`: reads a runtime secret from Databricks secret scope and lands sample raw events.
- `silver`: deduplicates and standardizes Bronze records.
- `gold`: aggregates Silver records into an event summary table.
- `smoke_test`: validates that each layer produced at least one row.

### Production notes

This implementation is deployment-ready for the repo contract, but some hardening remains intentionally documented instead of automated:

- remote Terraform backend
- cluster policies and more restrictive compute settings
- private networking and no-public-ingress workspace patterns
- monitoring, alerts, and system tables enablement
- real Bronze source integration instead of sample event generation
