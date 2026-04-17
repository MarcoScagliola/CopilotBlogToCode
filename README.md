# Secure Medallion Architecture on Azure Databricks

Infrastructure-as-code implementation of the [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268).

Each Medallion layer (Bronze, Silver, Gold) runs as an independent Lakeflow job under a dedicated service principal with tightly scoped, least-privilege access to its own storage account, compute cluster, and Unity Catalog catalog. No single identity, job, or cluster spans more than one layer.

See [SPEC.md](SPEC.md) for the full architecture description and [TODO.md](TODO.md) for prerequisites and post-deployment steps.

---

## Prerequisites

### Azure Service Principal
Create a service principal and assign the following:

| Permission | Scope | Required for |
|---|---|---|
| `Contributor` | Subscription | Create/manage Azure resources |
| `User Access Administrator` | Subscription | Assign roles to Access Connectors and layer SPs |
| `Application.ReadWrite.All` (Entra ID) | Directory | Create per-layer service principals (`create` mode only) |

> If your tenant restricts Entra app registration, use `existing` mode (see [TODO.md](TODO.md)).

---

## Required GitHub Secrets

### Always Required
Configure in GitHub Environment `BLG2CODEDEV` (**Settings → Environments**):

| Secret | Description |
|---|---|
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment service principal client ID |
| `AZURE_CLIENT_SECRET` | Deployment service principal client secret |

### Architecture-Specific (Post-Deployment)
These are **not** GitHub secrets – they are stored directly in Azure Key Vault after infrastructure is deployed:

| Key Vault Secret Key | Description |
|---|---|
| `jdbc-host` | JDBC source database hostname |
| `jdbc-database` | JDBC database name |
| `jdbc-user` | JDBC username |
| `jdbc-password` | JDBC password |

---

## Workflows

### 1. Validate Terraform
Validates Terraform syntax without provisioning. Runs automatically on push and pull requests.

```
Actions → Validate Terraform → Run workflow
```

### 2. Deploy Infrastructure
Provisions all Azure resources (storage, workspace, Unity Catalog, Key Vault) and uploads Terraform outputs as a workflow artifact.

```
Actions → Deploy Infrastructure → Run workflow
```

Inputs:

| Input | Default | Description |
|---|---|---|
| `target` | `dev` | DAB deployment target (`dev` or `prd`) |
| `environment` | `dev` | Terraform environment variable |
| `layer_sp_mode` | `create` | `create` (new per-layer SPs) or `existing` (reuse a single SP) |

> **State note**: Terraform uses local ephemeral state. Delete the resource group before rerunning. See [TODO.md](TODO.md) for remote backend setup.

### 3. Deploy DAB
Downloads the `terraform-outputs` artifact from the infrastructure run and deploys the Databricks Asset Bundle (Lakeflow jobs). No Databricks PAT required – authenticates via the same Azure SP.

```
Actions → Deploy DAB → Run workflow
```

---

## Local Usage

```bash
# Initialise and validate Terraform
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate

# Plan (requires Azure credentials in environment)
export TF_VAR_azure_tenant_id="<tenant-id>"
export TF_VAR_azure_subscription_id="<subscription-id>"
export TF_VAR_azure_client_id="<client-id>"
export TF_VAR_azure_client_secret="<client-secret>"
export TF_VAR_azure_sp_object_id="<sp-object-id>"
export TF_VAR_workload="blg"
export TF_VAR_environment="dev"
export TF_VAR_azure_region="uksouth"

terraform -chdir=infra/terraform plan

# Deploy Databricks bundle (after infrastructure is applied)
cd databricks-bundle
databricks bundle deploy --target dev
```
