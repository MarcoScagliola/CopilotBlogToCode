# Secure Medallion Regeneration

- Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Date: 2026-04-27
- Workload: `blg`
- Environment: `dev`
- Region: `uksouth`
- GitHub environment: `BLG2CODEDEV`
- Layer principal mode default: `create`

## Generated assets

- `.github/workflows/validate-terraform.yml`
- `.github/workflows/deploy-infrastructure.yml`
- `.github/workflows/deploy-dab.yml`
- `databricks-bundle/resources/jobs.yml`

## Authored assets restored

- `README.md`
- `SPEC.md`
- `TODO.md`
- `databricks-bundle/databricks.yml`
- `databricks-bundle/src/*/main.py`
- `infra/terraform/*.tf`

## Notes

- The Bronze job remains a sample ingest that reads a runtime secret and writes representative events.
- The implementation keeps a restricted-tenant-compatible `existing` principal mode alongside the default `create` mode.
- Post-deployment secret-scope creation and runtime secret population remain manual tasks.# Execution Record - 2026-04-27

- Source article: secure medallion architecture pattern on Azure Databricks (Part I)
- Defaults used: workload `blg`, environment `dev`, region `uksouth`, GitHub environment `BLG2CODEDEV`
- Generated artifacts: workflows, jobs resource, Terraform scaffold, Databricks bundle files, and deployment docs
- Validation required: Python compile, Terraform validate, YAML parse, post-deploy contract check, workflow parity# Execution Record - 2026-04-27

- Source article: secure medallion architecture pattern on Azure Databricks (Part I)
- Defaults used: workload `blg`, environment `dev`, region `uksouth`, GitHub environment `BLG2CODEDEV`
- Generated artifacts: workflows, jobs resource, Terraform scaffold, Databricks bundle files, and deployment docs
- Validation required: Python compile, Terraform validate, YAML parse, post-deploy contract check, workflow parity# Execution Record - 2026-04-27

- Source article: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- Defaults used: workload `blg`, environment `dev`, region `uksouth`, GitHub environment `BLG2CODEDEV`
- Generated artifacts: workflows, Terraform scaffold, Databricks bundle scaffold, README, TODO, SPEC
- Follow-up validation required: Python compile, Terraform validate, YAML parse, contract check