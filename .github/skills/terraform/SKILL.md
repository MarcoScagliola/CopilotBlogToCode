---
name: terraform
description: Generate production-ready Terraform code with provider compatibility, tenant flexibility, and secure defaults.
---

# Terraform Code Generation

## Overview
Guidance for generating Terraform infrastructure code that is maintainable, compatible with current provider versions, and adaptable to diverse cloud tenants and environments.

**Iteration policy.** This skill generates Terraform without `for_each` or `count`. All variation — per-layer resources, per-environment toggles, optional identities — is expressed by repeating resource blocks with explicit names, or by generating a different `main.tf` variant at code-generation time. Runtime Terraform is straight-line resource declarations. The rationale and the patterns that replace iteration are in Core Principle 7.

## Core Principles

### 1. Provider Compatibility
When generating code for cloud providers (AWS, Azure, GCP, etc.), prioritize deployment success over strict security defaults:

- **Prefer deployment-safe defaults** that work with the current provider version during create and update operations.
- **Avoid strict security settings that can break provisioning** if the provider still depends on older behaviors or polling mechanisms.
- **Understand provider behavior**: Some providers may still use control-plane authentication paths even when data-plane has stricter settings enabled.
- **Post-deployment hardening**: When stricter settings are desirable, make them configurable via input variables or document them as post-deployment hardening steps (e.g., "disable shared access keys after initial deployment").
- **Include comments**: Explain why a property is set to a particular value if it reflects a provider compatibility decision or limitation.
- **One-way properties are special.** Some resource properties are *immutable once enabled* at the cloud provider — once set to a particular value, they cannot be reverted. For these properties, "deployment-safe default" means *the value the resource will permanently carry from creation onward*, not *the value that makes the first deploy easiest to undo*. The latter framing is a trap: it produces code that works on the first deploy and fails on every subsequent modify. When generating code for such a property, set the permanent value explicitly and never offer the reversible-looking alternative. See *Key Vault Purge Protection* in Common Error Prevention for the canonical example. Other Azure properties in the same category include `enable_purge_protection` on Recovery Services Vaults, `enable_soft_delete` on Cognitive Services accounts, immutability policies on Storage containers, and `soft_delete_retention_days` on Key Vault (the value used at vault creation cannot be modified afterward, even though the property is not framed as a boolean toggle).
- **Security-tightening requires supporting infrastructure.** Some "secure default" properties only work when matching infrastructure is in place in the same configuration. For example, disabling public network access on a managed service typically requires private endpoints or VNet injection to be configured alongside. Customer-managed encryption keys require a Key Vault and access policies that the workload identity can use. Setting the security property without the supporting infrastructure produces a misconfigured resource that the cloud provider rejects at create time, often with cryptic errors. The generator MUST verify that any "more secure" property it sets has its supporting infrastructure in the same configuration. If the supporting infrastructure is out of scope for the current generation, the generator MUST keep the looser default and list the hardening as a post-deployment item in TODO.md.

### 2. Current vs. Deprecated Properties
Terraform providers introduce new properties and deprecate old ones over time. During code generation:

- **Always use current, non-deprecated property names** for resources and data sources.
- **Check provider documentation** for the latest property name before generating; deprecations can happen between minor releases.
- **Avoid deprecated arguments** even if they still work; future provider versions may remove them without notice.
- **Include comments** if a property choice reflects a provider version compatibility decision or avoids a deprecated alternative.
- **Search mechanism**: Use provider docs or changelog to identify if a property was recently renamed.
- **AzureRM property renames are version-dependent.** AzureRM 4.0 renamed many properties from `enable_<X>` to `<X>_enabled`. The generator MUST match the rename to the AzureRM version pinned in the configuration's `required_providers` block:
  - `~> 3.x`: use `enable_<X>` (the new name does not exist yet — using it produces an `unsupported argument` error).
  - `~> 4.x`: prefer `<X>_enabled` (the `enable_<X>` form still works but emits a deprecation warning).
  - `~> 5.x` and later: only `<X>_enabled` works.
  
  Examples: `enable_rbac_authorization` ↔ `rbac_authorization_enabled`, `enable_purge_protection` ↔ `purge_protection_enabled`, `enable_soft_delete` ↔ `soft_delete_enabled`. Always check the provider version pin before choosing the form.

### 3. Tenant and Environment Flexibility
Cloud deployments span different tenants, subscriptions, organizations, and regulatory environments. Generated code must adapt:

- **Do not assume uniform permissions** across all tenants (e.g., not all Azure tenants allow Entra app registration by service principals).
- **Support conditional identity provisioning**: when identity creation may be restricted, provide a mode to reuse an existing identity instead of creating new ones.
- **Example**: Generate a `service_principal_mode` variable with options `create` (new SP per layer) and `existing` (reuse provided SP).
- **Document compatibility paths**: if a feature may be restricted, spell out required inputs, secrets, or object identifiers for the alternative path.

### 4. State Management
Terraform state is the source of truth for resource management:

- **Prefer remote backends in production** (e.g., Azure Storage, S3, Terraform Cloud) for durability and team collaboration.
- **Local state is acceptable for development and ephemeral CI/CD** (e.g., GitHub Actions with per-workflow cleanup), but document the limitation.
- **Include backend block in version control** so future contributors understand the state architecture.
- **If ephemeral state is intentional**, explicitly document it and provide a deletion strategy (e.g., "delete Resource Group on rerun" or "configure remote backend for persistent state").

### 5. Resource Naming
All resource names follow a single canonical template, computed in `locals.tf` from semantic components:
`<resource-prefix>-{workload}-{environment}-{azure_region_abbrev}`

Where `{azure_region_abbrev}` is the *suffix* — always last, never in the middle. The full canonical names for resources referenced by both the Terraform module and the deployment workflow:

- Resource group: `rg-{workload}-{environment}-{azure_region_abbrev}`
- Key Vault: `kv-{workload}-{environment}-{azure_region_abbrev}` (lowercase, underscores stripped, truncated to 24 chars)
- Storage accounts: `st{workload}{environment}{layer}{azure_region_abbrev}` (lowercase, no hyphens, truncated to 24 chars)
- Databricks workspace: `dbw-{workload}-{environment}-{azure_region_abbrev}`

These patterns are non-negotiable. Specifically:
- Do not use a fixed suffix like `-platform` in place of the region abbreviation. Even if a source blog uses `-platform` in its examples, the canonical template overrides article naming.
- Do not include the region abbreviation in the *middle* of a name. It is always the last segment.
- Do not omit the region abbreviation. Every resource name has it, regardless of whether the deployment is single-region.

**Computation rules:**
- Compute names in `locals.tf` from input variables (`var.workload`, `var.environment`, `var.azure_region`). Convert `azure_region` to its abbreviation via the same mapping table the workflow uses (`uksouth → uks`, etc.).
- Do not accept resource names as direct input variables; compute them.
- Account for provider-specific length limits (e.g., Azure Storage accounts at 24 characters, Key Vaults at 24 characters).
- All resources of the same type must follow the same naming pattern.
- Document the convention in SPEC.md or README.md so users understand resource names in dashboards and CLI queries.

**Atomic updates across both sides.** A change to any naming pattern (a new region in the abbreviation table, a different truncation rule, a new resource type) requires updating both `locals.tf` and `generate_deploy_workflow.py` in the same commit. The parity check (`validate_workflow_parity.sh` or a peer `validate_resource_naming_parity.sh`) verifies that the generated workflow's `$rg_name` and `$kv_name` patterns match `locals.tf` before merge. Do not change one side and rely on the parity check to fail loudly — the parity check is a safety net, not the contract.

### 6. Variable Organization
Input variables structure the interface between code and consumers:

- **Group variables logically** (e.g., identity, storage, networking).
- **Provide sensible defaults** for optional values.
- **Mark sensitive variables** (passwords, tokens, keys) with `sensitive = true`.
- **Include validation rules** on enums (e.g., `service_principal_mode` must be "create" or "existing").
- **Use `trimspace()` (not `trim()`) when checking non-empty strings in validation blocks.** `trim(str, cutset)` requires two arguments and is not equivalent to whitespace stripping; `trimspace(str)` is the correct function.
- **Document assumptions** about variable origins (e.g., "tenant_id must come from GitHub Secrets, not hardcoded").

### 7. Resource Repetition Instead of Iteration

Generated code does not use `for_each` or `count`. Any variation that other Terraform codebases would express with iteration is expressed in this skill as:

1. Repeated resource blocks with explicit, descriptive names, when the variation lives within one generated module; or
2. Different generated `main.tf` variants chosen at code-generation time, when the variation distinguishes operational modes (e.g. `create` vs `existing` identities).

**Why.** `for_each` and `count` carry two failure modes that recur across deployments: plan-time unknown-keys errors when iteration keys derive from resource attributes, and "resource already exists" collisions when iteration does not vary the cloud-side identity tuple. Repetition makes the resource set visible to the reader, gives every resource a stable address that survives reorderings, and removes a category of error that would otherwise require its own ruleset.
 ...
}
```

Required shape (keys are static; values may be apply-time):

```hcl
locals {
  static_targets = {
    key_a = local.some_apply_time_map["key_a"]
    key_b = local.some_apply_time_map["key_b"]
  }
}

resource "some_resource" "example" {
  for_each = local.static_targets
  value    = each.value
}
```

If multiple variants collapse to the same identity, emit one static key (for example `shared`) instead of duplicating keys that point to the same value.

**Multiple similar resources — repeat the block with explicit names.** Per-layer, per-environment, or per-role resources are written out one block per instance:

```hcl
resource "azurerm_role_assignment" "kv_secrets_user_bronze" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_silver" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_gold" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.gold.object_id
}
```

Naming convention: `<resource-type>_<purpose>_<variant>`. The variant suffix (`bronze`, `silver`, `gold`, `deployment_sp`, `layer_sp`, etc.) is the dimension that would have been the `for_each` key.

**Shared identity — write a single resource, not three.** If the same principal serves all layers, emit one role assignment, not three blocks with the same `principal_id`:

```hcl
resource "azurerm_role_assignment" "kv_secrets_user_shared" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.existing_layer_sp_object_id
}
```

Th
**Legacy compatibility rule (non-overfitted).** This skill avoids iteration in new output, but when touching existing Terraform that already uses `for_each`, apply one invariant:

- `for_each` keys must be statically known at plan time.
- Resource-attribute values may appear in map values, not in keys.

Forbidden shape (keys come from apply-time values):

```hcl
locals {
  dynamic_ids = toset(values(local.some_apply_time_map))
}

resource "some_resource" "example" {
  for_each = local.dynamic_ids
  #is is the same rule that the old iteration guidance expressed as "drop the `for_each` when the iterating dimension does not vary identity" — restated for a repetition-based codebase as "don't write the same resource three times under different names."

**Operational modes — generate different `main.tf` variants.** When two modes need genuinely different resource sets (e.g. `identity_mode = "create"` creates service principals while `identity_mode = "existing"` does not), the choice is made at generation time, not at apply time. The generator emits one of two `main.tf` files. Within each generated file, every resource is unconditional.

This means there is no in-HCL conditional creation. There is no `count = var.flag ? 1 : 0`. There is no `for_each = local.maybe_empty_map`. Decisions about *whether* a resource exists are encoded in which file the generator wrote, not in arguments on the resource.

**Document both paths.** In README.md and variables.tf, describe each operational mode, what resources it produces, and which input variables it requires. The reader should be able to predict the generated resource set from the input variables without reading `main.tf`.

**Adding a new variant.** Adding a fourth layer (`platinum`) means adding the corresponding resource blocks — typically three to five blocks per layer (service principal, role assignment on Key Vault, role assignment on Storage, secret entry, etc.). This is intentional: the cost of adding a layer is visible in the diff. If the per-layer block count grows beyond ~5, that is a signal to factor the layer into a child module, not a signal to reach for `for_each`.

### 8. Documentation and Outputs
Generated code must be self-documenting:

- **Include comments** explaining non-obvious resource configurations, especially when they reflect provider compatibility decisions.
- **Export critical outputs** (resource IDs, endpoints, credentials references) for downstream systems.
- **Create SPEC.md** summarizing the architecture, key design decisions, and assumptions.
- **Create TODO.md** listing unresolved values, prerequisites, and manual setup steps.
- **Create README.md** with prerequisites, secrets, and workflow usage.

## Authentication and Credentials Policy

Secure handling of authentication credentials:

- **Never hardcode secrets**: All credentials must come from environment variables or secret management systems.
- **Use `sensitive = true`**: Mark password, token, and secret variables with `sensitive = true` to prevent accidental exposure.
- **Separate by scope**: Group authentication variables by their scope (tenant/org credentials, subscription/account credentials, resource credentials).
- **Document credential requirements**: In TODO.md, list all credentials needed and their originating source (e.g., "service principal credentials from GitHub Secrets").
- **Avoid cross-environment sharing**: Do not reuse credentials across tenants/accounts/environments unless explicitly intended.
- **Pin the credential variable contract**: The Terraform module's `variables.tf` declares the credential inputs the deployment workflow exports as `TF_VAR_*`. Both sides must use identical names. This baseline uses **unprefixed** names: `tenant_id`, `subscription_id`, `client_id`, `client_secret`, `sp_object_id`. Do not introduce `azure_*` or other provider prefixes for these specific variables — any drift between `variables.tf` and the workflow generator is a deploy-blocking error caught by `validate_workflow_parity.sh`.
- **Atomic updates across both sides**: If a future change introduces a new credential variable or renames an existing one, update `generate_deploy_workflow.py` and the `variables.tf` generation pattern in the same commit, and run `validate_workflow_parity.sh` to verify alignment before merging. Do not change one side and rely on the parity check to fail loudly — the parity check is a safety net, not the contract.
- **Cross-reference from the orchestrator**: The orchestrator's Step 5 (deploy-infrastructure workflow generation) must reference this credential variable contract, so an agent generating the workflow without loading the full terraform skill still produces names that align with `variables.tf`.

## Output Strategy

Outputs expose infrastructure properties to downstream systems, dashboards, and CLI consumers. Design outputs carefully:

- **Resource identifiers**: Export full resource IDs or ARNs (not just names) for CLI consumption and role assignments.
- **Service endpoints**: URLs, hostnames, or connection strings for application configuration.
- **Never export secrets**: Do not output credentials, API keys, or sensitive values; reference secrets in Key Vault/Secrets Manager instead.
- **Derived values**: Export computed names, tags, or resource groupings that consumers depend on.
- **Document assumptions**: Comment on output format and required downstream processing.

## Terraform File Structure

Organize Terraform code for clarity and maintainability:

- **`versions.tf`**: Provider requirements and Terraform version constraint
- **`providers.tf`**: Provider configuration and authentication
- **`variables.tf`**: All input variables, grouped by logical domain (identity, storage, networking, etc.)
- **`locals.tf`**: All derived values (names, conditional logic, computed maps)
- **`main.tf`**: Resource definitions
- **`outputs.tf`**: Exported values for downstream systems
- **`backend.tf` (optional)**: Remote backend configuration for state persistence

## Common Error Prevention

Address these common Terraform deployment error categories in generated code. The skill's no-iteration policy (Core Principle 7) removes a class of errors that other Terraform codebases hit — `Invalid for_each argument`, "resource already exists" from `for_each` collisions, plan-time unknown-keys — so those categories do not appear here. The errors below are the ones that remain.

### RBAC / Permission Errors (403 Forbidden)
**Error**: Provider unable to read subscriptions, create resources, or perform operations.
**Prevention**:
- Assume the service principal may lack baseline permissions.
- Document required RBAC roles in TODO.md and README.md (e.g., "Contributor on subscription", "Directory.ReadWrite.All in Entra ID").
- For CI/CD, explicitly pass credentials as variables rather than relying on implicit authentication.
- Include a validation step (e.g., role assignment verification) before deployment.

### Identity Creation Restrictions (Authorization_RequestDenied)
**Error**: Tenant policy prevents identity creation (Entra app registration, custom roles, service principals).
**Prevention**:
- Do not assume every tenant allows identity creation.
- Implement conditional identity provisioning by generating one of two `main.tf` variants at code-generation time (per Core Principle 7): a `create` variant that emits the service principal resources, and an `existing` variant that omits them and consumes object IDs as input variables.
- In variables.tf, provide a mode variable (e.g., `identity_mode = "create" | "existing"`) and document both paths. The variable controls which variant the generator emits; it does not appear as a conditional in the resulting HCL.
- When reusing existing identities, require explicit object ID or client ID inputs in variables.tf.
- When reusing existing identities, avoid mandatory Microsoft Graph reads during apply (for example data-source lookups that require directory read permissions); prefer direct use of provided service principal object IDs for RBAC assignments.
- Add notes in README.md about restricted-tenant workarounds.

### Provider Behavior Mismatches (Data Plane Auth, Polling)
**Error**: Provider control-plane expects one auth method but data-plane uses another; provider still uses legacy auth during resource polling.
**Prevention**:
- Use deployment-safe defaults (e.g., enable key-based auth on storage, not disable it) and make strictness configurable.
- Add comments in main.tf explaining why a property is set this way (e.g., "Storage shared_access_key_enabled=true because AzureRM provider still polls blob storage with key auth").
- Provide variables for post-deployment hardening (e.g., `storage_shared_key_enabled = var.enable_shared_key` defaulting to true).
- In README.md, document post-deployment hardening steps under "Optional Security Enhancements".

### Key Vault Soft-Delete Recovery (SoftDeletedVaultDoesNotExist / Recovery Disabled)
**Error**: After `terraform destroy` or resource group deletion, Azure retains the vault in a soft-deleted state. On the next `terraform apply`, the AzureRM provider raises `automatically recovering this KeyVault has been disabled`.
**Prevention**:
- Make Key Vault recovery configurable in provider settings (for example `recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted`) instead of hardcoding one value.
- In CI/CD workflows, detect whether a soft-deleted vault with the target name exists and set the Terraform variable per run.
- This avoids both failure modes: recovery-disabled when a deleted vault exists, and `SoftDeletedVaultDoesNotExist` when recovery is forced but no deleted vault exists.

### Key Vault Purge Protection (immutable once enabled; provider sends full state on update)
**Error**: `once Purge Protection has been Enabled it's not possible to disable it`, even when the apparent change in the plan is unrelated (tags, SKU, network ACLs, access policies).

**Root cause**: `purge_protection_enabled` is a one-way flag in Azure — once `true`, it cannot be reverted to `false`. The AzureRM provider sends the full vault property set on every update, not just the changed fields. If `purge_protection_enabled` is omitted from the Terraform resource, the provider serializes the implicit default (`false`) into the update request. Azure rejects the request as an attempt to disable purge protection, regardless of what the operator intended to change.

A deeper trap: "deployment-safe default" thinking can mislead the generator into setting `false` to make the *first* deploy easier to undo (no 7-90 day soft-delete wait on destroy). This convenience is available on the first deploy only. From the second deploy onward, the same value becomes a deploy blocker because Azure will not let the modify proceed. The property's true deployment-safe value is the value the resource will *permanently* carry from creation onward — which is `true`.

**Prevention**:
- Always set `purge_protection_enabled = true` explicitly in the generated `azurerm_key_vault` resource. Treat it as mandatory, not optional, regardless of deployment scenario.
- Never omit the argument. Omission causes the provider to send `false` on every update, breaking any subsequent apply (tag change, SKU upgrade, network ACL update) against a vault whose actual state has purge protection enabled.
- Never set it to `false`. The argument has no `false` value in practice — once a vault exists with it enabled, no operation can disable it, so emitting `false` only produces errors.
- Recovered vaults, vaults from previous deployments, and vaults created by other tooling may all carry `purge_protection_enabled = true` regardless of how they were provisioned. Assume any existing vault has it enabled.

### Key Vault Authorisation Model: RBAC Only, No Access Policies

**Rule.** Generated `azurerm_key_vault` resources MUST set `enable_rbac_authorization = true`. The `azurerm_key_vault_access_policy` resource type is forbidden in generated code. All grants on a Key Vault MUST be expressed as `azurerm_role_assignment` resources scoped to the vault, using Key Vault data-plane RBAC roles (`Key Vault Secrets Officer` for principals that manage secrets, `Key Vault Secrets User` for principals that only read them).

**Why.** Access policies are a legacy authorisation model on Azure Key Vault. They have three concrete problems that RBAC does not:

1. **Recovery conflicts.** A vault recovered from soft-delete retains every `azurerm_key_vault_access_policy` it had at deletion time, identified by `(vault, objectId)` pair. Terraform's state, fresh on the new run, knows nothing about these preserved policies and tries to create them again. Azure rejects with `already exists - to be managed via Terraform this resource needs to be imported`. The conflict recurs on every redeploy against a recovered vault.

2. **RBAC role assignments survive recovery cleanly.** Role assignments are identified by GUID. When a vault is recovered, prior role assignments do not survive in a way that conflicts with new assignments. Terraform creates fresh assignments cleanly. Recovery scenarios are transparent.

3. **Access policies and RBAC mode are mutually exclusive.** A vault with `enable_rbac_authorization = true` ignores access policy resources, which means access policy resources in `main.tf` are dead code at best and import conflicts at worst.

**What to emit instead.** The generated `azurerm_key_vault` resource must contain:

    enable_rbac_authorization = true

For every principal that needs vault access, emit an `azurerm_role_assignment` block scoped to the vault:

    resource "azurerm_role_assignment" "kv_<role-name>" {
      scope                = azurerm_key_vault.main.id
      role_definition_name = "Key Vault Secrets Officer"   # or "Key Vault Secrets User"
      principal_id         = <principal_object_id>
    }

The deployment principal typically gets `Key Vault Secrets Officer` (read, write, delete, recover, purge on secrets). Workload principals that only read secrets get `Key Vault Secrets User`.

**What is forbidden:**
- `azurerm_key_vault_access_policy` as a resource type, anywhere.
- `enable_rbac_authorization = false` on a Key Vault.
- Omitting `enable_rbac_authorization` entirely, since the AzureRM provider default is `false` and omission has the same effect as explicitly setting the legacy mode.
- Mixing access policies and RBAC role assignments on the same vault.

**Source article handling.** If the source article describes access policies explicitly (e.g. "the deployment principal needs Get, List, Set on the vault"), translate those permissions into the equivalent RBAC role and emit the role assignment. Do not preserve the access-policy vocabulary in the generated code. SPEC.md should record the article's wording faithfully; `main.tf` follows this skill, not the article.

### State Management (already exists / needs import)

**Error**: `A resource with the ID "..." already exists - to be managed via Terraform this resource needs to be imported into the State.`

**Root cause**: Terraform tries to create an Azure resource whose ID is already present in Azure. The resource is not in Terraform's state, so Terraform doesn't know it exists; Azure rejects the create because the ID is taken.

This commonly fires for two distinct reasons:

1. **The parent resource is leftover from a prior deploy.** The Key Vault, the resource group, or the workspace was created in a previous run that left no state. Terraform sees the absence in state and tries to recreate. Importing the parent resource into state resolves this case.

2. **A child resource preserved itself across a parent recreate.** This is the subtler case. The parent (e.g. a Key Vault) is recovered from soft-delete or imported, and the recovery brings back *child* resources that were attached when the parent was deleted — Key Vault access policies, network ACL rules, resource locks. Terraform creates the parent cleanly but then fails on the first child it tries to create, because the recovered parent carries the child as part of its own state.

   Specifically: a Key Vault recovered from soft-delete retains every `azurerm_key_vault_access_policy` it had at deletion time. The `azurerm_key_vault.main` resource creates cleanly, but `azurerm_key_vault_access_policy.<name>` fails because the policy already exists in Azure. (This is one of the reasons access policies are forbidden — see the section above.)

**Prevention**:
- Treat `already exists` errors as *resource-specific*, not Key-Vault-specific. The error message names the resource address and the Azure resource ID — use both. A recovery handler that imports only `azurerm_key_vault.main` will not resolve the same error on `azurerm_key_vault_access_policy.deployment_sp`.
- After recovering a Key Vault from soft-delete, the recovery handler MUST expect access policy conflicts if any legacy access policies exist. Even though new code emits RBAC role assignments instead, a vault inherited from older deployments may still carry access policies. The handler must enumerate and import each preserved access policy individually, by Terraform resource address and by Azure resource ID — or the operator must delete them via the Azure CLI before reapplying.
- When recreating a resource group that contained a Key Vault with attached access policies, the policies will survive into the recovered vault. The deployer cannot prevent this on the Azure side — purge protection prevents the policies from being permanently deleted along with the vault. The only options are (a) wait out the soft-delete retention window before redeploying, or (b) import each preserved access policy into the new state.

**Resource-specific import patterns** (extend as new cases surface):

| Azure error mentions | Terraform resource address | Azure resource ID shape |
|---|---|---|
| `Microsoft.KeyVault/vaults/<name>` | `azurerm_key_vault.main` | `/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>` |
| `Microsoft.KeyVault/vaults/<name>/objectId/<oid>` | `azurerm_key_vault_access_policy.deployment_sp` or `azurerm_key_vault_access_policy.layer_sp["<layer>"]` | `/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>/objectId/<oid>` |
| `Microsoft.Authorization/roleAssignments/<guid>` | `azurerm_role_assignment.<name>` | the full role assignment ID |
| `Microsoft.Databricks/workspaces/<name>` | `azurerm_databricks_workspace.main` | the full workspace ID |

## Pre-Generation Validation
Before writing Terraform code, validate the generation strategy:

- [ ] **Provider and authentication**: Identify the target provider (AWS, Azure, GCP) and authentication method (service principal, IAM role, static credentials)
- [ ] **Permission model**: Understand what base permissions are required (e.g., Contributor on subscription, Directory admin) and document in TODO.md
- [ ] **Tenant/environment restrictions**: Are there known restrictions (e.g., identity creation not allowed, custom roles not available)?
- [ ] **Naming strategy**: Define semantic components (workload, environment, region) that will drive `locals.tf` name derivation
- [ ] **State persistence**: Will state be remote (production) or local/ephemeral (CI/CD)? Document both the choice and the cleanup strategy.
- [ ] **Secret handling**: Where will credentials come from (GitHub Secrets, HashiCorp Vault, environment variables)? Mark all secret variables with `sensitive = true`.
- [ ] **Error scenarios**: Identify which error types from "Common Error Prevention" might occur in your environment and ensure corresponding safeguards are in place.
- [ ] **Credentials and assumptions**: Document any assumptions about pre-existing identities, permissions, or resources in variables.tf and TODO.md.

## Implementation Checklist
**Code Quality**
- [ ] Provider versions pinned in `versions.tf`
- [ ] All variables grouped and documented in `variables.tf`
- [ ] Sensitive variables marked with `sensitive = true`
- [ ] Validation rules applied to enum or restricted-value variables
- [ ] Resource names computed in `locals.tf` (not accepted as input variables)
- [ ] No `for_each` argument appears anywhere in generated Terraform. Verify with: `grep -nE '^\s*for_each' infra/terraform/*.tf` returns no matches.
- [ ] No `count` argument appears anywhere in generated Terraform. Verify with: `grep -nE '^\s*count\s*=' infra/terraform/*.tf` returns no matches.
- [ ] Multiple similar resources (per-layer, per-environment, per-role) are written as separate resource blocks with explicit, descriptive names following `<resource-type>_<purpose>_<variant>`.
- [ ] Operational-mode variation (e.g. `identity_mode = "create" | "existing"`) is handled by generating different `main.tf` variants at code-generation time, not by in-HCL conditionals.
- [ ] No hardcoded credentials or secrets in code
- [ ] Deprecated provider properties avoided

**Error Prevention and Compatibility**
- [ ] Deployment-safe defaults used for security-sensitive properties (with migration path to stricter settings)
- [ ] Provider compatibility decisions documented in comments
- [ ] Conditional identity provisioning implemented if identity creation may be restricted
- [ ] RBAC/permission requirements documented in TODO.md and README.md
- [ ] State persistence strategy documented (remote backend, local/ephemeral state, or other)
- [ ] Cleanup/teardown strategy provided for ephemeral state scenarios
- [ ] `purge_protection_enabled = true` is set explicitly on every `azurerm_key_vault` resource — never omitted, never `false` — to prevent modify-time failures from the provider serialising the implicit default.
- [ ] Key Vault authorisation mode is set to RBAC explicitly: `enable_rbac_authorization = true` (AzureRM 3.x) or `rbac_authorization_enabled = true` (AzureRM 4.x or later), depending on the provider version pinned in the configuration. No `azurerm_key_vault_access_policy` resources appear anywhere in generated code.
- [ ] AzureRM property naming matches the provider version pinned in `required_providers`. On `~> 3.x`, `enable_<X>` is correct; on `~> 4.x` or later, `<X>_enabled` is correct. Verify with: read the version pin first, then grep for the matching naming convention.
- [ ] `soft_delete_retention_days` on `azurerm_key_vault` matches the value the vault will hold permanently. If a vault already exists with a different value, the generated code must reflect the existing value, not the desired new value, since the property is one-way.
- [ ] Security-tightening properties (network access disabled, identity-only auth, customer-managed keys) only appear when the matching supporting infrastructure is in the same configuration. Otherwise the looser default is used and the hardening is listed in TODO.md.

**Outputs and Documentation**
- [ ] Critical resource identifiers (IDs, ARNs) exported as outputs
- [ ] Service endpoints exported for application configuration
- [ ] No secrets or credentials in outputs
- [ ] Comments in code explain non-obvious logic, especially provider compatibility decisions
- [ ] SPEC.md created with architecture summary and key design decisions
- [ ] TODO.md created with unresolved values, prerequisites, and RBAC requirements
- [ ] README.md created with prerequisites, required credentials, state strategy, and post-deployment steps
- [ ] Terraform syntax validated (`terraform validate` or `terraform init -backend=false && terraform validate`)