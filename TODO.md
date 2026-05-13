# TODO - blg dev

## Pre-deployment
- Confirm deployment principal has Contributor and User Access Administrator on the target scope.
- Confirm deployment principal has Entra app-registration permissions for create mode.
- Confirm GitHub Environment BLG2CODEDEV contains required Azure identity secrets.

## Deployment-time inputs
- Select key_vault_recovery_mode per run; default to auto for reruns.
- Select state_strategy per run; use fail for non-destructive behavior.
- Keep layer_sp_mode set to create for this generated variant.

## Post-infrastructure
- Create Databricks secret scope backed by the generated Key Vault.
- Populate Key Vault with runtime secret values required by ingestion and transformation code.
- Validate Unity Catalog grants for bronze, silver, and gold execution principals.

## Post-DAB
- Run orchestrator job once and confirm all layer jobs succeed.
- Verify bronze, silver, and gold tables exist and contain expected rows.
- Configure production schedules and alerting after smoke-test success.

## Architectural decisions deferred
- Decide whether to move Terraform state to a remote backend for non-destructive reruns.
- Decide whether and when to disable shared key access on storage accounts as a hardening step.
- Finalize enterprise data-governance model for downstream consumer groups.
