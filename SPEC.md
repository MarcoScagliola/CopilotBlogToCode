# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Title: Secure Medallion Architecture Pattern on Azure Databricks – Part I

## Architecture Summary
- Pattern: bronze, silver, and gold layers on Azure Databricks with Unity Catalog governance.
- Security model: per-layer identities, least-privilege access, and Key Vault-backed secret handling.
- Storage model: ADLS Gen2 accounts scoped to medallion layers.
- Orchestration model: setup plus bronze, silver, gold, and smoke-test jobs coordinated by an orchestrator job.

## Stated or Inferred from Article
- Medallion layering is explicitly used for progressive data quality and curation.
- Unity Catalog is used for governance and controlled access to data assets.
- Azure Databricks is the compute and orchestration plane.
- Key Vault-backed secret usage is part of the secure design intent.
- Layer separation by identity and storage boundary is part of the design intent.

## Not Stated in Article
- Exact source systems and ingestion protocols: not stated in article.
- Full runtime secret key inventory and naming convention: not stated in article.
- Complete catalog and schema naming standards per environment: not stated in article.
- Full grant matrix for user groups, BI consumers, and service principals: not stated in article.
- Monitoring baselines and alert thresholds: not stated in article.
- Disaster recovery, backup, and retention policies: not stated in article.
- Production remote Terraform state design and locking model: not stated in article.
- Cost guardrails and budget controls for cluster/job execution: not stated in article.

## Decisions for This Generation Run
- Workload code: blg
- Environment: dev
- Azure region: uksouth
- Layer identity mode: create (new layer service principals created by Terraform)
- GitHub environment for workflows: BLG2CODEDEV

## Name Mapping Used in This Run
- Resource group: rg-blg-dev-uks
- Key Vault: kv-blg-dev-uks
- Databricks workspace: dbw-blg-dev-uks
- Storage accounts: stblgdevbronzeuks, stblgdevsilveruks, stblgdevgolduks
- Secret scope name in bundle defaults: kv-dev-scope

## Other Observations
- The article provides architecture direction and security posture but intentionally leaves environment-specific operational values to implementation.
- Generated assets are scaffolded for repeatable deployment; production hardening decisions remain in TODO.md.
