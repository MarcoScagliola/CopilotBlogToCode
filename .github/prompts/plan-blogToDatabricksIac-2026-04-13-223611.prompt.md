Execution Plan - Secure Medallion Architecture (blg/dev/uksouth)

1. Build Terraform foundation files (versions/providers/variables/locals) pinned to required provider versions and context-driven naming.
2. Implement Azure + Databricks resources in main.tf for secure medallion pattern:
   - Resource group, Databricks workspace, per-layer ADLS Gen2 storage.
   - Entra applications/service principals per layer with least-privilege RBAC.
   - Databricks Access Connectors, Unity Catalog catalogs/schemas, storage credentials, external locations.
   - Azure Key Vault and AKV-backed Databricks secret scope.
3. Add outputs for workspace URL/resource ID and operational identifiers used by DAB.
4. Create Databricks Asset Bundle config and 4 jobs (bronze/silver/gold/orchestrator) with variable injection for host/catalogs/SP IDs/secret scope.
5. Implement notebook/job Python entrypoints for Bronze/Silver/Gold/Orchestrator, reading secrets at runtime via dbutils.secrets where needed.
6. Update SPEC.md, TODO.md, and README.md with architecture rationale, assumptions, workflow usage, and required secret names including AZURE_TENANT_ID/AZURE_SUBSCRIPTION_ID.
7. Run a lightweight Terraform validation pass if toolchain is available and summarize assumptions.
