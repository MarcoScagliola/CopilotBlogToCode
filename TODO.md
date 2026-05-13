# TODO - blg dev

## Pre-deployment
- Confirm the deployment principal has Contributor and User Access Administrator on the target Azure scope.
- Confirm the deployment principal can create Entra service principals for create mode.
- Create the GitHub Environment BLG2CODEDEV and store the Azure credential secrets there.

## Deployment-time inputs
- Choose key_vault_recovery_mode for the run; use auto for normal reruns.
- Choose state_strategy for the run; use fail for safe reruns.
- Keep layer_sp_mode set to create for this generated variant.

## Post-infrastructure
- Create the Databricks secret scope backed by the generated Azure Key Vault.
- Populate Azure Key Vault with the runtime secrets required by the notebooks and jobs.
- Verify Unity Catalog grants for bronze, silver, and gold identities.

## Post-DAB
- Run the orchestrator job and verify all three layer jobs succeed.
- Verify bronze, silver, and gold target tables contain expected rows.
- Enable schedules and notifications only after a successful smoke test.

## Architectural decisions deferred
- Decide whether to move Terraform state to a remote backend for incremental reruns.
- Decide whether to disable shared key access on storage accounts after provisioning.
- Finalize the downstream consumer access model for the curated datasets.
