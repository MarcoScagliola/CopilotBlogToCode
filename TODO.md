# TODO - blg dev

## Required Before First Deployment

- Confirm whether you want `layer_sp_mode=create` or `layer_sp_mode=existing` for this environment.
- If using `layer_sp_mode=existing`, populate `EXISTING_LAYER_SP_CLIENT_ID` and `EXISTING_LAYER_SP_OBJECT_ID` in `BLG2CODEDEV`.
- Ensure the deployment principal has `Contributor` and `User Access Administrator` on the target scope.
- If using `layer_sp_mode=create`, ensure the deployment principal has permission to create Entra applications and service principals.
- Confirm the GitHub environment `BLG2CODEDEV` exists and contains all required Azure credentials.

## Deployment-Time Inputs Still Open

- Exact Bronze ingestion source and format are not stated in the article.
- Exact schema names are not stated in the article.
- Scheduling cadence and SLA targets are not stated in the article.
- The article does not define production DR or retention requirements.

## Post-Infrastructure Deployment

- Create the Azure Key Vault-backed Databricks secret scope using the Key Vault created by Terraform.
- Add the runtime secret key `source-system-token` to Azure Key Vault.
- Confirm the layer principals and access connectors have the required RBAC and Unity Catalog privileges.
- Verify the Databricks workspace can resolve Key Vault secrets through the secret scope.

## Post-DAB Deployment

- Run the orchestrator job once end to end.
- Confirm the setup job created the target catalogs and schemas.
- Confirm Bronze wrote `raw_events`, Silver wrote `events`, and Gold wrote `event_summary`.
- Review failures for missing secrets, missing grants, or storage access issues before retrying.

## Architectural Decisions Deferred

- Configure a remote Terraform backend before production use.
- Decide whether to disable shared key access on storage accounts after initial provisioning.
- Add Databricks system tables, diagnostics, and alert routing for operational visibility.
- Replace the sample Bronze ingestion logic with the real source-system implementation.