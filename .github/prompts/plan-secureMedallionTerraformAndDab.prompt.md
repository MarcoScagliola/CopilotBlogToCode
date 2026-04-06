## Plan: Secure Medallion Terraform And DAB

Generate the Azure Databricks secure medallion pattern from the blog into this repo using the existing skeleton folders. The implementation should produce a concise architecture spec, a TODO gap list, Terraform for Azure plus Unity Catalog infrastructure, and a Databricks bundle for jobs and notebooks. Terraform and the bundle stay cleanly separated: Terraform owns Azure and Unity Catalog infrastructure; the bundle owns Lakeflow jobs, clusters, and notebook code.

**Steps**
1. Confirm the output boundaries from the article and skill. The blog is explicit about three isolated layers, each with its own storage account, identity, service principal, access connector, external location, catalog access pattern, compute profile, and Lakeflow job. It also calls for one shared Key Vault per environment and one orchestrator job spanning Bronze, Silver, and Gold.
2. Fill the existing Terraform skeleton under the existing directories rather than scaffolding new folders.
Phase A: foundation.
Add provider/version constraints for `azurerm`, `azuread`, and `databricks`, plus variables for subscription, region, naming prefix, environment, Databricks workspace URL, Databricks account ID, metastore ID, tags, and the layer list.
3. Add the Azure infrastructure in Terraform.
Phase B: Azure resources.
Provision a resource group, three ADLS Gen2 storage accounts, one `data` container per account, three user-assigned managed identities, three Databricks access connectors, RBAC for write-to-own-layer and read-from-upstream-layer, and one Azure Key Vault with RBAC-based secret access.
4. Add the Databricks and Unity Catalog infrastructure in Terraform.
Phase C: Databricks and Unity Catalog.
Create three Entra applications and service principals, register them in the Databricks account, create storage credentials and external locations per layer, create Bronze/Silver/Gold catalogs and default schemas, and grant each principal access only to its own layer plus read access to the immediate upstream layer.
5. Add Terraform outputs for values the bundle will consume later, especially service principal application IDs, storage account IDs, access connector IDs, catalog names, and the Key Vault URI.
6. Generate the repo-root deliverables required by the skill.
Phase D: generated docs.
`SPEC.md` should capture the source article, short summary, inferred architecture, explicit guidance, assumptions, and missing values. `TODO.md` should contain unresolved values only: region, workspace/account identifiers, metastore ID, secret scope, catalog/schema choices if they differ from defaults, schedules, notifications, optional networking IDs, and any external source storage identifiers.
7. Fill the existing bundle skeleton.
Phase E: bundle definition.
Create `databricks.yml` with host and target variables, environment targets, a secret scope variable, orchestrator schedule variable, and service-principal variables sourced from Terraform outputs.
8. Add the bundle job resources.
Phase F: Lakeflow jobs.
Create three layer jobs plus one orchestrator in `resources/jobs.yml`. Each layer job runs as its own service principal and uses its own cluster definition. Bronze and Gold default to Photon off; Silver defaults to Photon on. The orchestrator uses sequential `run_job_task` dependencies across Bronze, Silver, and Gold.
9. Add notebook entrypoints in the bundle source folder.
Phase G: notebook scaffolds.
Create one notebook or script per layer with placeholder ingestion, refinement, and curation logic. Each should show runtime secret access through `dbutils.secrets.get`, read and write managed tables under Unity Catalog, and avoid environment-specific constants in code.
10. Keep scope separation strict.
Do not put Azure infrastructure, Unity Catalog storage credentials, external locations, or Key Vault provisioning into the bundle. Do not add `pipelines.yml` unless the implementation intentionally switches to DLT pipelines, which the article does not require.
11. Update the repo README so usage is accurate for this workflow: fetch the blog, generate outputs with the skill, fill TODO values, apply Terraform, then validate, deploy, and run the bundle.
12. Verify the finished implementation with Terraform formatting and validation, bundle validation, and a manual separation-of-responsibilities review.

**Relevant files**
- [SKILL.md](.github/skills/blog-to-databricks-iac/SKILL.md) — source workflow and expected output shape
- [output-contract.md](.github/skills/blog-to-databricks-iac/templates/output-contract.md) — required output order and file list
- [README.md](README.md) — existing repo README to update so it matches the generated workflow

**Verification**
1. Run `python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py <BLOG_URL>` and confirm it returns parsed article JSON.
2. Run `terraform fmt -check` and `terraform validate` in `infra/terraform` after inputs are filled.
3. Run `databricks bundle validate -t dev` in `databricks-bundle`.
4. Manually confirm Terraform owns Azure resources, identities, RBAC, Key Vault, and Unity Catalog objects, while the bundle owns only jobs, clusters, and notebooks.
5. Manually confirm all unknown values are surfaced in `TODO.md` rather than being hard-coded across generated files.

**Decisions**
- Included: storage accounts, managed identities, access connectors, Key Vault, Entra service principals, Databricks account registration, Unity Catalog storage credentials, external locations, catalogs, schemas, grants, bundle jobs, and notebook scaffolds.
- Excluded: CI/CD pipelines, environment promotion workflows, advanced network injection, and cluster-policy automation unless the implementation is deliberately extended beyond the article.
- Assumption: managed tables remain the table strategy because the article explicitly recommends them.
- Assumption: `pipelines.yml` is unnecessary because the article centers on Lakeflow Jobs, not DLT pipelines.

**Further Considerations**
1. Cluster policies are in the article, but they may be better treated as a later extension if workspace-admin ownership is separate from app deployment ownership.
2. AKV-backed secret scope creation may need to stay manual or CLI-driven depending on the target Databricks API and provider support.
3. If you want stricter environment isolation, the implementation can add per-environment naming prefixes and separate Key Vault names without changing the Terraform-versus-bundle boundary.
