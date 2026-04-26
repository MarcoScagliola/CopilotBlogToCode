# TODO - Secure Medallion Databricks Deployment

## Required Before First Deployment
- Confirm workload naming tokens and region abbreviation policy used by your organization.
- Confirm whether layer identities are created by Terraform (`layer_sp_mode=create`) or reused (`layer_sp_mode=existing`).
- If `layer_sp_mode=existing`, populate:
  - `EXISTING_LAYER_SP_CLIENT_ID`
  - `EXISTING_LAYER_SP_OBJECT_ID`
- Confirm GitHub Environment exists: `BLG2CODEDEV`.

## Post-Infrastructure Deployment
- Create AKV-backed Databricks secret scope in workspace.
- Populate runtime secrets in Azure Key Vault (source credentials/API tokens).
- Grant Unity Catalog privileges for layer principals and Access Connectors.
- Validate catalog and schema ownership model for Bronze/Silver/Gold.

## Security and Operations Follow-up
- Enable and verify Databricks system tables required for monitoring.
- Configure job failure alerts (email/webhook) per environment.
- Review Key Vault access logs and configure retention.
- Decide and apply secret rotation cadence.

## State Management
- CI currently supports ephemeral/local Terraform state workflows.
- For production, configure a remote backend and state locking before broad rollout.
- If rerunning with local state and existing resources, use controlled import or reset strategy.

## Open Architecture Inputs (not stated in article)
- Final cluster sizes and autoscaling bounds by layer.
- Exact ingestion source for Bronze (event stream, files, database, etc.).
- SLA/SLO targets for orchestration frequency and retry policy.
- Final naming for catalogs/schemas/tables beyond defaults.
- Disaster recovery and multi-region failover requirements.
