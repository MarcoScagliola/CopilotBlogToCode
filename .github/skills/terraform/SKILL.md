---
name: terraform
description: Generate production-ready Terraform code with provider compatibility, tenant flexibility, and secure defaults.
---

# Terraform Code Generation

## Overview
Guidance for generating Terraform infrastructure code that is maintainable, compatible with current provider versions, and adaptable to diverse cloud tenants and environments.

## Core Principles

### 1. Provider Compatibility
When generating code for cloud providers (AWS, Azure, GCP, etc.), prioritize deployment success over strict security defaults:

- **Prefer deployment-safe defaults** that work with the current provider version during create and update operations.
- **Avoid strict security settings that can break provisioning** if the provider still depends on older behaviors or polling mechanisms.
- **Understand provider behavior**: Some providers may still use control-plane authentication paths even when data-plane has stricter settings enabled.
- **Post-deployment hardening**: When stricter settings are desirable, make them configurable via input variables or document them as post-deployment hardening steps (e.g., "disable shared access keys after initial deployment").
- **Include comments**: Explain why a property is set to a particular value if it reflects a provider compatibility decision or limitation.
- **Example pattern**: Enable authentication method by default, provide variable to disable it post-deployment; include comment explaining the provider behavior that necessitates this approach.
- **One-way properties are special.** Some resource properties are *immutable
  once enabled* at the cloud provider — once set to a particular value, they
  cannot be reverted. For these properties, "deployment-safe default" means
  *the value the resource will permanently carry from creation onward*, not
  *the value that makes the first deploy easiest to undo*. The latter framing
  is a trap: it produces code that works on the first deploy and fails on
  every subsequent modify. When generating code for such a property, set the
  permanent value explicitly and never offer the reversible-looking alternative.
  See *Key Vault Purge Protection* in Common Error Prevention for the canonical
  example. Other Azure properties in the same category include
  `enable_purge_protection` on Recovery Services Vaults, `enable_soft_delete`
  on Cognitive Services accounts, and immutability policies on Storage
  containers.

### 2. Current vs. Deprecated Properties
Terraform providers introduce new properties and deprecate old ones over time. During code generation:

- **Always use current, non-deprecated property names** for resources and data sources.
- **Check provider documentation** for the latest property name before generating; deprecations can happen between minor releases.
- **Avoid deprecated arguments** even if they still work; future provider versions may remove them without notice.
- **Include comments** if a property choice reflects a provider version compatibility decision or avoids a deprecated alternative.
- **Search mechanism**: Use provider docs or changelog to identify if a property was recently renamed.

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

Compute names in `locals.tf` from input variables (`var.workload`, `var.environment`, `var.azure_region`). Convert `azure_region` to its abbreviation via the same mapping table the workflow uses (`uksouth → uks`, etc.). Both sides — `locals.tf` and `generate_deploy_workflow.py` — must reference the same mapping table.

Do not accept resource names as direct input variables; compute them.

Document the convention in SPEC.md or README.md.

**Atomic updates across both sides.** A change to any naming pattern (a new region in the abbreviation table, a different truncation rule, a new resource type) requires updating both `locals.tf` and `generate_deploy_workflow.py` in the same commit. The parity check (`validate_workflow_parity.sh` or a peer `validate_resource_naming_parity.sh`) verifies that the generated workflow's `$rg_name` and `$kv_name` patterns match `locals.tf` before merge. Do not change one side and rely on the parity check to fail loudly — the parity check is a safety net, not the contract.

## Authentication and Credentials Policy

Establish secure handling of authentication credentials:

- **Never hardcode secrets**: All credentials must come from environment variables or secret management systems.
- **Use sensitive = true**: Mark password, token, and secret variables with `sensitive = true` to prevent accidental exposure.
- **Separate by scope**: Group authentication variables by their scope (tenant/org credentials, subscription/account credentials, resource credentials).
- **Document credential requirements**: In TODO.md, list all credentials needed and their originating source (e.g., "service principal credentials from GitHub Secrets").
- **Avoid cross-environment sharing**: Do not reuse credentials across tenants/accounts/environments unless explicitly intended.
- **Pin the credential variable contract**: The Terraform module's `variables.tf` declares the credential inputs the deployment workflow exports as `TF_VAR_*`. Both sides must use identical names. This baseline uses **unprefixed** names: `tenant_id`, `subscription_id`, `client_id`, `client_secret`, `sp_object_id`. Do not introduce `azure_*` or other provider prefixes for these specific variables — any drift between `variables.tf` and the workflow generator is a deploy-blocking error caught by `validate_workflow_parity.sh`.
- **Atomic updates across both sides**: If a future change introduces a new credential variable or renames an existing one, update `generate_deploy_workflow.py` and the `variables.tf` generation pattern in the same commit, and run `validate_workflow_parity.sh` to verify alignment before merging. Do not change one side and rely on the parity check to fail loudly — the parity check is a safety net, not the contract.
- **Cross-reference from the orchestrator**: The orchestrator's Step 5 (deploy-infrastructure workflow generation) must reference this credential variable contract, so an agent generating the workflow without loading the full terraform skill still produces names that align with `variables.tf`.

### 6. Variable Organization
Input variables structure the interface between code and consumers:

- **Group variables logically** (e.g., identity, storage, networking).
- **Provide sensible defaults** for optional values.
- **Mark sensitive variables** (passwords, tokens, keys) with `sensitive = true`.
- **Include validation rules** on enums (e.g., `service_principal_mode` must be "create" or "existing").
- **Use `trimspace()` (not `trim()`) when checking non-empty strings in validation blocks.** `trim(str, cutset)` requires two arguments and is not equivalent to whitespace stripping; `trimspace(str)` is the correct function.
- **Document assumptions** about variable origins (e.g., "tenant_id must come from GitHub Secrets, not hardcoded").

### 7. Conditional Resource Creation
When generating code for different operational modes or constraints:

- **Use `for_each` for optional resources** based on input variables, environment, or feature flags.
- **Compute the condition in `locals.tf`** for clarity and to avoid repeating complex logic across resources.
- **Use when identity creation is restricted**: Provide a variable (e.g., `create_new_identities`) and conditionally create identities or reuse input identifiers.
- **Use when permissions vary**: Conditionally assign roles or resources based on what the deployment environment allows.
- **Example pattern**:
  ```hcl
  locals {
    should_create_identity = var.identity_mode == "create"
    identities_to_create   = local.should_create_identity ? { new = true } : {}
  }
  
  resource "aws_iam_role" "custom_role" {
    for_each = local.identities_to_create
    # ...
  }
  ```
- **Document both paths**: In README.md and variables.tf, explain what each mode does and why a user might choose one over the other.

### 8. Iteration Shape vs. Resource Identity
When using `for_each` or `count` to create multiple instances of a resource, two independent rules apply: iteration must vary the resource's identity at the cloud provider, **and** iteration keys must be statically known at plan time.

**Identity rule.** Each iteration must produce a distinct identity tuple at the provider:

- **Identify the provider's identity tuple** for each resource type. For role assignments this is typically `(scope, role, principal)`; for storage objects it may be `(account, container, name)`; for DNS records `(zone, name, type)`.
- **Ensure the iteration varies at least one component of that tuple.** If every `for_each` instance produces the same identity tuple, all instances collide on a single cloud-side resource. Terraform will create one successfully and fail the rest with a "resource already exists" error.
- **When the iterating dimension does not actually vary identity, drop the iteration.** A single resource is the right shape, even if it feels asymmetric with neighboring iterating resources.
- **Compute the identity-varying component explicitly** (e.g. `each.value.principal_object_id` rather than a shared `var.principal_id`) so the divergence is visible in code review.

**Plan-time knowability rule.** `for_each` keys must be determinable before any resource is applied:

- **Iterate over static sources.** The `for_each` argument's *keys* must come from input variables, hardcoded sets, or locals that do not depend on resource attributes. Map *values* may reference apply-time attributes; only keys must be static.
- **Do not pass a resource as a `for_each` source** when downstream resources also iterate over it (e.g. `for_each = aws_iam_role.layer`). Even though Terraform allows it syntactically, it fails at plan time when the upstream resource's keys themselves derive from apply-time data, or when the planner cannot prove they don't.
- **Pattern: parallel iteration over a shared static map.** When creating "one B per A," both A and B should iterate over the same static map, and B should reference A by key:
```hcl
  resource "_a" "layer" {
    for_each = local.layers           # static keys
    # ...
  }

  resource "_b" "layer" {
    for_each = local.layers           # same static keys
    a_id     = _a.layer[each.key].id   # apply-time value, lookup by static key
  }
```
- **Hoist keys out of derived locals.** If a `local` driving iteration is computed from anything that might be apply-time, separate the static key set from the apply-time values:
```hcl
  locals {
    layer_names = toset(["bronze", "silver", "gold"])   # static
    layers = { for n in local.layer_names : n => { ... } }
  }
```

**Document why iteration is safe** when the answer isn't obvious — a one-line comment on the `for_each` explaining which dimension makes each instance unique and where the keys come from.

### 9. Documentation and Outputs
Generated code must be self-documenting:

- **Include comments** explaining non-obvious resource configurations, especially when they reflect provider compatibility decisions.
- **Export critical outputs** (resource IDs, endpoints, credentials) for downstream systems.
- **Create SPEC.md** summarizing the architecture, key design decisions, and assumptions.
- **Create TODO.md** listing unresolved values, prerequisites, and manual setup steps.
- **Create README.md** with prerequisites, secrets, and workflow usage.

## Authentication and Credentials Policy

Establish secure handling of authentication credentials:

- **Never hardcode secrets**: All credentials must come from environment variables or secret management systems
- **Use sensitive = true**: Mark password, token, and secret variables with `sensitive = true` to prevent accidental exposure
- **Separate by scope**: Group authentication variables by their scope (tenant/org credentials, subscription/account credentials, resource credentials)
- **Document credential requirements**: In TODO.md, list all credentials needed and their originating source (e.g., "service principal credentials from GitHub Secrets")
- **Avoid cross-environment sharing**: Do not reuse credentials across tenants/accounts/environments unless explicitly intended

## Resource Naming Strategy

All resource names must be systematic and derived from semantic components:

- **Name computation location**: Define all naming logic in `locals.tf`, never accept resource names as Terraform variables
- **Semantic components**: names should derive from workload identifier, deployment environment, and geographic region
- **Consistency**: All resources of the same type must follow the same naming pattern (e.g., all storage resources include region abbreviation)
- **Length constraints**: Account for provider-specific limits (e.g., some providers limit names to 24 characters, others to 64)
- **Document the convention**: Include naming pattern in SPEC.md so users understand resource names in dashboards/CLI queries

## Output Strategy

Outputs expose infrastructure properties to downstream systems, dashboards, and CLI consumers. Design outputs carefully:

- **Resource identifiers**: Export full resource IDs or ARNs (not just names) for CLI consumption and role assignments
- **Service endpoints**: URLs, hostnames, or connection strings for application configuration
- **Never export secrets**: Do not output credentials, API keys, or sensitive values; reference secrets in Key Vault/Secrets Manager instead
- **Derived values**: Export computed names, tags, or resource groupings that consumers depend on
- **Document assumptions**: Comment on output format and required downstream processing

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

Address these common Terraform deployment error categories in generated code:

### RBAC / Permission Errors (403 Forbidden)
**Error**: Provider unable to read subscriptions, create resources, or perform operations.
**Prevention**:
- Assume the service principal may lack baseline permissions
- Document required RBAC roles in TODO.md and README.md (e.g., "Contributor on subscription", "Directory.ReadWrite.All in Entra ID")
- For CI/CD, explicitly pass credentials as variables rather than relying on implicit authentication
- Include a validation step (e.g., role assignment verification) before deployment

### Identity Creation Restrictions (Authorization_RequestDenied)
**Error**: Tenant policy prevents identity creation (Entra app registration, custom roles, service principals).
**Prevention**:
- Do not assume every tenant allows identity creation
- Implement conditional identity provisioning via `for_each` (create new identity) or variable inputs (reuse existing identity)
- In variables.tf, provide a mode variable (e.g., `identity_mode = "create" | "existing"`) and document both paths
- When reusing existing identities, require explicit object ID or client ID inputs in variables.tf
- When reusing existing identities, avoid mandatory Microsoft Graph reads during apply (for example data-source lookups that require directory read permissions); prefer direct use of provided service principal object IDs for RBAC assignments
- Add notes in README.md about restricted-tenant workarounds

### Iteration Collisions on Shared Identity (Resource Already Exists)
**Error**: Multiple `for_each` or `count` instances of the same resource fail at apply time with "already exists" / 409 / 409 Conflict, where the existing resource ID matches the one another iteration produced. The first instance creates the cloud resource; the rest collide on the same resource identity.
**Prevention**:
- When using `for_each` to create per-environment, per-layer, or per-tenant resources that depend on an identity (principal, IAM role, account), confirm the identity actually varies per iteration. If `principal_id` (or its equivalent) is the same expression for every `for_each` instance, the iterations collide.
- If the identity is shared by design (one principal serving all layers), drop the `for_each` and create a single resource. Iteration is the wrong shape when the iterating dimension does not vary identity.
- If the design genuinely requires per-iteration identities, ensure the iteration source (`local.layers`, `local.environments`, etc.) carries a distinct identity per entry, and reference it via `each.value.<identity_field>` rather than a top-level `var.*`.
- Symptom to watch for: identical resource IDs reported in the error message across multiple `for_each` keys, or a refresh phase that shows the same ID under a different `for_each` key than the one currently failing.

### Unknown Keys in for_each (Invalid for_each argument)
**Error**: `Invalid for_each argument` at plan time, with message "The 'for_each' map includes keys derived from resource attributes that cannot be determined until apply."
**Prevention**:
- The `for_each` argument's *keys* must be derivable at plan time. Values can be apply-time; keys cannot.
- Do not use one resource as the `for_each` source for another (`for_each = some_resource.layer`). Iterate both over the same static map and look up the upstream resource by key: `some_resource.layer[each.key]`.
- If a `local` that drives iteration is computed from data sources or other resources, separate the static key dimension from the apply-time value dimension. Hoist keys into a `toset(...)` or static map; let values carry the apply-time fields.
- Reach for `-target` only as a last resort. Two-phase apply usually masks a structural issue that's better fixed by making keys static.
- Symptom to watch for: the error names a specific resource attribute as "known only after apply," and the failing `for_each` references another resource directly rather than a static local or variable.

### Provider Behavior Mismatches (Data Plane Auth, Polling)
**Error**: Provider control-plane expects one auth method but data-plane uses another; provider still uses legacy auth during resource polling.
**Prevention**:
- Use deployment-safe defaults (e.g., enable key-based auth on storage, not disable it) and make strictness configurable
- Add comments in main.tf explaining why a property is set this way (e.g., "Storage shared_access_key_enabled=true because AzureRM provider still polls blob storage with key auth")
- Provide variables for post-deployment hardening (e.g., `storage_shared_key_enabled = var.enable_shared_key` defaulting to true)
- In README.md, document post-deployment hardening steps under "Optional Security Enhancements"

### Key Vault Soft-Delete Recovery (SoftDeletedVaultDoesNotExist / Recovery Disabled)
**Error**: After `terraform destroy` or resource group deletion, Azure retains the vault in a soft-deleted state. On the next `terraform apply`, the AzureRM provider raises `automatically recovering this KeyVault has been disabled`.
**Prevention**:
- Make Key Vault recovery configurable in provider settings (for example `recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted`) instead of hardcoding one value.
- In CI/CD workflows, detect whether a soft-deleted vault with the target name exists and set the Terraform variable per run.
- This avoids both failure modes: recovery-disabled when a deleted vault exists, and `SoftDeletedVaultDoesNotExist` when recovery is forced but no deleted vault exists.

### Key Vault Purge Protection (immutable once enabled; provider sends full state on update)
**Error**: `once Purge Protection has been Enabled it's not possible to disable it`, even when
the apparent change in the plan is unrelated (tags, SKU, network ACLs, access policies).
**Root cause**: `purge_protection_enabled` is a one-way flag in Azure — once `true`, it cannot
be reverted to `false`. The AzureRM provider sends the full vault property set on every update,
not just the changed fields. If `purge_protection_enabled` is omitted from the Terraform
resource, the provider serializes the implicit default (`false`) into the update request. Azure
rejects the request as an attempt to disable purge protection, regardless of what the operator
intended to change.

A deeper trap: "deployment-safe default" thinking can mislead the generator into setting
`false` to make the *first* deploy easier to undo (no 7-90 day soft-delete wait on destroy).
This convenience is available on the first deploy only. From the second deploy onward, the
same value becomes a deploy blocker because Azure will not let the modify proceed. The
property's true deployment-safe value is the value the resource will *permanently* carry
from creation onward — which is `true`.

**Prevention**:
- Always set `purge_protection_enabled = true` explicitly in the generated `azurerm_key_vault`
  resource. Treat it as mandatory, not optional, regardless of deployment scenario.
- Never omit the argument. Omission causes the provider to send `false` on every update,
  breaking any subsequent apply (tag change, SKU upgrade, network ACL update) against a vault
  whose actual state has purge protection enabled.
- Never set it to `false`. The argument has no `false` value in practice — once a vault
  exists with it enabled, no operation can disable it, so emitting `false` only produces
  errors.
- Recovered vaults, vaults from previous deployments, and vaults created by other tooling
  may all carry `purge_protection_enabled = true` regardless of how they were provisioned.
  Assume any existing vault has it enabled.

### State Management (already exists / needs import)

**Error**: `A resource with the ID "..." already exists - to be managed via
Terraform this resource needs to be imported into the State.`

**Root cause**: Terraform tries to create an Azure resource whose ID is already
present in Azure. The resource is not in Terraform's state, so Terraform doesn't
know it exists; Azure rejects the create because the ID is taken.

This commonly fires for two distinct reasons:

1. **The parent resource is leftover from a prior deploy.** The Key Vault, the
   resource group, or the workspace was created in a previous run that left no
   state. Terraform sees the absence in state and tries to recreate. Importing
   the parent resource into state resolves this case.

2. **A child resource preserved itself across a parent recreate.** This is the
   subtler case. The parent (e.g. a Key Vault) is recovered from soft-delete or
   imported, and the recovery brings back *child* resources that were attached
   when the parent was deleted — Key Vault access policies, network ACL rules,
   resource locks. Terraform creates the parent cleanly but then fails on the
   first child it tries to create, because the recovered parent carries the
   child as part of its own state.

   Specifically: a Key Vault recovered from soft-delete retains every
   `azurerm_key_vault_access_policy` it had at deletion time. The
   `azurerm_key_vault.main` resource creates cleanly, but
   `azurerm_key_vault_access_policy.<name>` fails because the policy already
   exists in Azure.

**Prevention**:

- Treat `already exists` errors as *resource-specific*, not Key-Vault-specific.
  The error message names the resource address and the Azure resource ID — use
  both. A recovery handler that imports only `azurerm_key_vault.main` will not
  resolve the same error on `azurerm_key_vault_access_policy.deployment_sp`.

- After recovering a Key Vault from soft-delete, the recovery handler MUST
  expect access policy conflicts. The deployment SP access policy and every
  layer SP access policy will fail on first apply if they were attached to the
  vault before its deletion. The handler must enumerate and import each access
  policy individually, by Terraform resource address and by Azure resource ID.

- When recreating a resource group that contained a Key Vault with attached
  access policies, the policies will survive into the recovered vault. The
  deployer cannot prevent this on the Azure side — purge protection prevents
  the policies from being permanently deleted along with the vault. The only
  options are (a) wait out the soft-delete retention window before redeploying,
  or (b) import each preserved access policy into the new state.

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
- [ ] Conditional resources use `for_each` with conditions computed in `locals.tf`
- [ ] No hardcoded credentials or secrets in code
- [ ] Deprecated provider properties avoided
- [ ] `for_each` and `count` iterations vary at least one component of the resulting resource's identity tuple
- [ ] `for_each` keys come from static sources (input variables, hardcoded sets, locals not derived from resource attributes); apply-time data appears only in values

**Error Prevention and Compatibility**
- [ ] Deployment-safe defaults used for security-sensitive properties (with migration path to stricter settings)
- [ ] Provider compatibility decisions documented in comments
- [ ] Conditional identity provisioning implemented if identity creation may be restricted
- [ ] RBAC/permission requirements documented in TODO.md and README.md
- [ ] State persistence strategy documented (remote backend, local/ephemeral state, or other)
- [ ] Cleanup/teardown strategy provided for ephemeral state scenarios
- [ ] `purge_protection_enabled = true` is set explicitly on every `azurerm_key_vault` resource — never omitted, never `false` — to prevent modify-time failures from the provider serialising the implicit default.

**Outputs and Documentation**
- [ ] Critical resource identifiers (IDs, ARNs) exported as outputs
- [ ] Service endpoints exported for application configuration
- [ ] No secrets or credentials in outputs
- [ ] Comments in code explain non-obvious logic, especially provider compatibility decisions
- [ ] SPEC.md created with architecture summary and key design decisions
- [ ] TODO.md created with unresolved values, prerequisites, and RBAC requirements
- [ ] README.md created with prerequisites, required credentials, state strategy, and post-deployment steps
- [ ] Terraform syntax validated (`terraform validate or terraform init -backend=false && terraform validate`)

