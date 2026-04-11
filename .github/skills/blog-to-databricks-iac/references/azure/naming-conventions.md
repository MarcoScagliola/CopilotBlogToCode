# Naming Conventions

## Microsoft CAF References

- [Resource naming rules and best practices](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Recommended abbreviations by resource type](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

## Naming Pattern

All resource names are derived in `locals.tf` from three inputs only:

| Input | Description | Example |
|-------|-------------|---------|
| `workload` | Short identifier for the project | `mdln` |
| `environment` | Deployment environment | `dev`, `prod` |
| `azure_region` | Azure region (used to derive abbreviation) | `uksouth` → `uks` |

## Pattern per Resource Type

| Resource | Pattern | Example (`mdln`, `prod`, `uks`) |
|----------|---------|----------------------------------|
| Resource group | `rg-<workload>-<env>-<abbr>` | `rg-mdln-prod-uks` |
| Databricks workspace | `dbw-<workload>-<env>-<abbr>` | `dbw-mdln-prod-uks` |
| Storage account (no hyphens, max 24) | `st<workload><layer><env>` | `stmdlnbrzprod` |
| Access Connector | `dbac-<workload>-<layer>-<env>-<abbr>` | `dbac-mdln-brz-prod-uks` |
| Entra App | `app-<workload>-<layer>-<env>` | `app-mdln-brz-prod` |
| Key Vault | `kv-<workload>-<env>-<abbr>` | `kv-mdln-prod-uks` |
| UC storage credential | `sc-<workload>-<layer>-<env>` | `sc-mdln-brz-prod` |
| UC external location | `el-<workload>-<layer>-<env>` | `el-mdln-brz-prod` |
| UC catalog | `<workload>_<layer>_<env>` | `mdln_brz_prod` |
| UC schema | `<layer>_schema` | `bronze_schema` |
| Lakeflow job | `job-<workload>-<layer>-<env>` | `job-mdln-brz-prod` |
| Job cluster | `jc-<workload>-<layer>-<env>` | `jc-mdln-brz-prod` |

## Layer Abbreviations

| Layer | Abbreviation |
|-------|-------------|
| bronze | `brz` |
| silver | `slv` |
| gold | `gld` |
| orchestrator | `orch` |

## Region Abbreviations

See `locals.tf` for the full map. Common examples:

| Region | Abbreviation |
|--------|-------------|
| `uksouth` | `uks` |
| `ukwest` | `ukw` |
| `westeurope` | `weu` |
| `northeurope` | `neu` |
| `eastus` | `eus` |
| `eastus2` | `eus2` |
| `westus2` | `wus2` |

## Constraints

- **Storage accounts:** No hyphens, lowercase, 3–24 characters. The pattern `st<workload><layer><env>` must stay within 24 chars — keep `workload` short (e.g., 4–6 chars).
- **Key Vault:** 3–24 characters, globally unique — include the region abbreviation in the name.
- **UC names:** Use underscores (not hyphens) since Unity Catalog rejects hyphens in catalog and schema names.
- **Do not override names** unless there is a hard naming requirement from the customer. All names should come from `locals.tf`.
