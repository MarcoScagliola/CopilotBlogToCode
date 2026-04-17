# Secure Medallion On Databricks (Blog Implementation)

This workspace implements a reproducible baseline of the architecture described in:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

The baseline enforces Bronze/Silver/Gold separation with dedicated jobs and identity-scoped access paths, then deploys infrastructure and Databricks assets through split CI workflows.

## Prerequisites

- Azure service principal with permissions to create resource groups, storage, Key Vault resources, role assignments, and Entra app/service principal objects.
- GitHub Environment configured for deployment credentials.
- Terraform and Databricks CLI available in CI runner context.

## Required GitHub secrets or variables

### Always required

| Name | Purpose |
|---|---|
| AZURE_TENANT_ID | ARM tenant id |
| AZURE_SUBSCRIPTION_ID | ARM subscription id |
| AZURE_CLIENT_ID | Deployment service principal client id |
| AZURE_CLIENT_SECRET | Deployment service principal secret |
| AZURE_SP_OBJECT_ID | Deployment service principal object id for RBAC |

### Architecture-specific / conditional

| Name | When needed | Purpose |
|---|---|---|
| EXISTING_LAYER_SP_CLIENT_ID | `layer_sp_mode=existing` | Layer execution principal client id |
| EXISTING_LAYER_SP_OBJECT_ID | `layer_sp_mode=existing` | Layer execution principal object id |

If conditional values are omitted in existing mode, workflow fallback uses deployment principal values.

## One-time setup steps

1. Register the deployment service principal and capture client id, secret, and object id.
2. Assign required Azure RBAC roles in the target subscription or resource group.
3. Configure GitHub Environment `BLG2CODEDEV` with required values (as secrets or vars).
4. Ensure repository Actions permissions allow artifact upload/download.

## Workflows

1. `Validate Terraform`
	- Trigger manually from Actions UI.
	- Runs Terraform init (no backend) and validate.

2. `Deploy Infrastructure`
	- Trigger manually and select inputs (target/workload/environment/region/layer mode).
	- Runs Terraform apply.
	- Publishes `terraform-outputs` and `deploy-context` artifacts.

3. `Deploy DAB`
	- Trigger manually with `infra_run_id` or let it run after successful infrastructure workflow.
	- Downloads artifacts, checks out matching commit SHA, and deploys the Databricks bundle.

## References

- SPEC: `SPEC.md`
- TODO: `TODO.md`
