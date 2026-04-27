## Source

- Article: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- Pattern: Azure Databricks medallion architecture with isolated Bronze, Silver, and Gold processing layers.
- Orchestration: one Lakeflow job per layer plus one orchestrator job.
- Security model: least privilege across identities, storage, and compute.
- Governance model: Unity Catalog with separate catalogs per medallion layer.

## Azure services used

- Azure Databricks workspace.
- Azure Data Lake Storage Gen2.
- Azure Databricks Access Connector.
- Azure Key Vault.
- Microsoft Entra service principals or existing principals reused by input.

## Data layout

- Bronze catalog and schema for raw events.
- Silver catalog and schema for cleansed events.
- Gold catalog and schema for aggregate summaries.
- Managed tables selected over externally managed table paths.

## Isolation model

- Separate storage accounts per layer.
- Separate logical execution identities per layer.
- Separate Access Connectors per layer.
- Separate job clusters per layer in the generated bundle.

## Security notes from the article

- Secrets should not be stored in code, repos, or job parameters.
- Runtime secrets should be retrieved from AKV-backed Databricks secret scopes.
- Least privilege should prevent a lower layer from reading or corrupting higher layers.
- Monitoring and system tables should be enabled from day one.

## Values not fully stated in the article

- Exact resource naming convention: implemented with this repo's standard naming rules.
- Exact CI/CD workflow layout: implemented with split infrastructure and DAB workflows.
- Exact source-system integration details for Bronze ingestion: not stated in article.
- Exact private networking topology for the workspace: not stated in article.
- Exact production alerting thresholds and dashboards: not stated in article.

## Implementation choices in this repo

- Default workload/environment/region: `blg` / `dev` / `uksouth`.
- Identity mode supports both `create` and `existing` to stay compatible with restricted tenants.
- The sample Bronze job uses a runtime secret named `source-system-token` and writes representative sample events.
- The DAB deploy bridge uses Terraform outputs plus static bundle defaults for schema names.

## Other observations

- The article explicitly defers some operational concerns to Part II; those items remain documented in `TODO.md` instead of being over-automated here.