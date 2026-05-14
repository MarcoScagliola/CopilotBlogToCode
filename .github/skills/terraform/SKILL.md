---
name: terraform
description: Generate production-ready Terraform code with provider compatibility, tenant flexibility, and secure defaults.
---

# Terraform Code Generation

## Overview
Guidance for generating Terraform infrastructure code that is maintainable, compatible with current provider versions, and adaptable to diverse cloud tenants and environments.

**Iteration policy.** This skill generates Terraform without `for_each` or `count`. All variation — per-instance resources, per-environment toggles, optional identities — is expressed by repeating resource blocks with explicit names, or by generating a different `main.tf` variant at code-generation time. Runtime Terraform is straight-line resource declarations. The rationale and the patterns that replace iteration are in Core Principle 7.

## Core Principles

### 1. Provider Compatibility
When generating code for cloud providers, prioritize deployment success over strict security defaults:

- **Prefer deployment-safe defaults** that work with the current provider version during create and update operations.
- **Avoid strict security settings that can break provisioning** if the provider still depends on older behaviors or polling mechanisms.
- **Understand provider behavior**: control-plane and data-plane authentication paths may differ; some providers still use legacy auth during resource polling even when stricter modes are configured.
- **Post-deployment hardening**: when stricter settings are desirable, make them configurable via input variables or document them as post-deployment hardening steps.
- **Include comments**: explain why a property is set to a particular value if it reflects a provider compatibility decision or limitation.
- **One-way properties are special.** Some resource properties are *immutable once enabled* at the cloud provider — once set, they cannot be reverted. For these properties, "deployment-safe default" means *the value the resource will permanently carry from creation onward*, not *the value that makes the first deploy easiest to undo*. The latter framing is a trap: it produces code that works on the first deploy and fails on every subsequent modify. When generating code for such a property, set the permanent value explicitly and never offer the reversible-looking alternative. The canonical example is documented in *Key Vault Purge Protection* under Common Error Prevention; the same pattern applies to soft-delete toggles, immutability policies, and one-way retention settings on other resources.
- **Security-tightening requires supporting infrastructure.** Some "secure default" properties only work when matching infrastructure is in place in the same configuration (e.g. disabling public network access requires private endpoints or network injection; customer-managed encryption keys require a key store and access grants). Setting the security property without the supporting infrastructure produces a misconfigured resource the cloud provider rejects at create time. The generator MUST verify that any "more secure" property it sets has its supporting infrastructure in the same configuration. If the supporting infrastructure is out of scope for the current generation, the generator MUST keep the looser default and list the hardening as a post-deployment item in TODO.md.

### 2. Current vs. Deprecated Properties
Terraform providers introduce new properties and deprecate old ones over time. During code generation:

- **Always use current, non-deprecated property names** for resources and data sources.
- **Check provider documentation** for the latest property name before generating; deprecations can happen between minor releases.
- **Avoid deprecated arguments** even if they still work; future provider versions may remove them without notice.
- **Include comments** if a property choice reflects a provider version compatibility decision.
- **Search mechanism**: use provider docs or changelog to identify if a property was recently renamed.
- **Provider-version-dependent renames.** When a major provider release renames properties (e.g. boolean prefix changes from `enable_<X>` to `<X>_enabled`), the generator MUST match the rename to the version pinned in `required_providers`. Older pin → older name; newer pin → newer name. Mixing the two produces `unsupported argument` errors or deprecation warnings depending on which side of the rename is wrong. Always check the version pin before choosing the form.

### 3. Tenant and Environment Flexibility
Cloud deployments span different tenants, subscriptions, organizations, and regulatory environments. Generated code must adapt:

- **Do not assume uniform permissions** across all tenants (e.g. not every tenant allows identity creation by an automated principal).
- **Support conditional identity provisioning**: when identity creation may be restricted, provide a mode to reuse an existing identity instead of creating new ones.
- **Document compatibility paths**: if a feature may be restricted, spell out required inputs, secrets, or object identifiers for the alternative path.

### 4. State Management
Terraform state is the source of truth for resource management:

- **Prefer remote backends in production** for durability and team collaboration.
- **Local state is acceptable for development and ephemeral CI/CD**, but document the limitation.
- **Include backend block in version control** so future contributors understand the state architecture.
- **If ephemeral state is intentional**, explicitly document it and provide a deletion strategy.

### 5. Resource Naming
All resource names follow a single canonical template, computed in `locals.tf` from semantic components: `<resource-prefix>-{workload}-{environment}-{region-abbrev}`. The region abbreviation is the *suffix* — always last, never in the middle, never omitted.

**Computation rules:**
- Compute names in `locals.tf` from input variables. Convert verbose region names to abbreviations via the same mapping table the deployment workflow uses.
- Do not accept resource names as direct input variables; compute them.
- Account for provider-specific length and character-set limits (some cloud resources require lowercase, no hyphens, fixed maximum lengths).
- All resources of the same type follow the same naming pattern.
- Document the convention in SPEC.md or README.md so users understand resource names in dashboards and CLI queries.

**Atomic updates across both sides.** A change to any naming pattern (a new region in the abbreviation table, a different truncation rule, a new resource type) requires updating both `locals.tf` and the deployment workflow generator in the same commit. The parity check verifies that workflow-computed names match `locals.tf` before merge. Do not change one side and rely on the parity check to fail loudly — the parity check is a safety net, not the contract.

### 6. Variable Organization
Input variables structure the interface between code and consumers:

- **Group variables logically** (identity, storage, networking).
- **Provide sensible defaults** for optional values.
- **Mark sensitive variables** with `sensitive = true`.
- **Include validation rules** on enums.
- **Use `trimspace()` (not `trim()`) when checking non-empty strings in validation blocks.** `trim(str, cutset)` requires two arguments and is not equivalent to whitespace stripping.
- **Document assumptions** about variable origins.

### 7. Resource Repetition Instead of Iteration

Generated code does not use `for_each` or `count`. Variation is expressed as:

1. Repeated resource blocks with explicit, descriptive names, when the variation lives within one generated module; or
2. Different generated `main.tf` variants chosen at code-generation time, when the variation distinguishes operational modes.

**Why.** `for_each` and `count` carry two failure modes that recur across deployments: plan-time unknown-keys errors when iteration keys derive from resource attributes, and "resource already exists" collisions when iteration does not vary the cloud-side identity tuple. Repetition makes the resource set visible to the reader, gives every resource a stable address that survives reorderings, and removes a category of error that would otherwise require its own ruleset.

**Multiple similar resources — repeat the block with explicit names.** Per-instance resources (per-layer, per-environment, per-role) are written out one block per instance. Naming convention: `<resource-type>_<purpose>_<variant>`. The variant suffix is the dimension that would have been the `for_each` key.

**Shared identity — write a single resource, not three.** If the same principal serves all instances, emit one block, not duplicates with the same key value. This is the same rule that the old iteration guidance expressed as "drop the `for_each` when the iterating dimension does not vary identity" — restated for a repetition-based codebase as "don't write the same resource three times under different names."

**Legacy compatibility rule.** This skill avoids iteration in new output, but when touching existing Terraform that already uses `for_each`, apply one invariant:

- `for_each` keys must be statically known at plan time.
- Resource-attribute values may appear in map values, not in keys.

If multiple variants collapse to the same identity, emit one static key (e.g. `shared`) instead of duplicating keys that point to the same value.

**Operational modes — generate different `main.tf` variants.** When two modes need genuinely different resource sets (e.g. an identity mode that creates principals vs. one that reuses them), the choice is made at generation time, not at apply time. The generator emits one of two `main.tf` files. Within each generated file, every resource is unconditional.

This means no in-HCL conditional creation. No `count = var.flag ? 1 : 0`. No `for_each = local.maybe_empty_map`. Decisions about *whether* a resource exists are encoded in which file the generator wrote, not in arguments on the resource.

**Document both paths.** In README.md and variables.tf, describe each operational mode, what resources it produces, and which input variables it requires. The reader should be able to predict the generated resource set from the input variables without reading `main.tf`.

**Adding a new variant.** Adding a new instance to a repeated family means adding every block in that family for the new instance. Per-instance families typically include the identity itself, its registrations in downstream systems, role assignments, secret entries, and any related grants. The cost of adding an instance is visible in the diff. If the per-instance block count grows beyond what can be scanned at a glance, that is a signal to factor the instance into a child module, not a signal to reach for `for_each`.

### 8. Documentation and Outputs
Generated code must be self-documenting:

- **Include comments** explaining non-obvious resource configurations.
- **Export critical outputs** (resource IDs, endpoints, credentials references) for downstream systems.
- **Create SPEC.md** summarizing the architecture, key design decisions, and assumptions.
- **Create TODO.md** listing unresolved values, prerequisites, and manual setup steps.
- **Create README.md** with prerequisites, secrets, and workflow usage.

## Required Outputs

Some resources MUST appear in every generated module whenever their upstream condition is met. These rules fire on every generation, not only when an error has been observed.

### Cross-system identity bridging

When an identity created in one system (cloud provider, IdP, directory) is referenced from a separate system that maintains its own identity table (e.g. a workspace, a SaaS application, a Kubernetes cluster), the second system MUST also have a registration resource for that identity in the same Terraform module. The two resources are two halves of one identity:

- The originating identity in its native system.
- A registration of that identity in any system that will reference it.

The registration MUST source its identity reference from the originating resource, never from a hardcoded value or input variable. Hardcoded references decouple the two halves and silently break when the underlying identity rotates.

The registration MUST declare `depends_on` on the resource that hosts the registering system, so the host exists before registration is attempted.

This rule applies regardless of whether the source article describes the bridging step explicitly, regardless of vocabulary, and regardless of which operational mode the generator is producing. If the module creates an identity that any in-module resource references in another system, it registers it.

**Required provider configuration.** When a module emits registration resources for a target system, the provider for that system MUST be declared in `versions.tf` and configured in `providers.tf` against the host resource. Authentication for the target-system provider reuses credentials already present in the module's environment wherever possible — no separate token paths.

**Validation.** Before completing generation, verify that the count of originating identities matches the count of registrations for every target system the module emits to. A count mismatch is a generation failure, not a warning. Add the missing registrations and regenerate any outputs that depend on them.

## Authentication and Credentials Policy

Secure handling of authentication credentials:

- **Never hardcode secrets**: all credentials come from environment variables or secret management systems.
- **Use `sensitive = true`**: mark credential variables to prevent accidental exposure.
- **Separate by scope**: group authentication variables by their scope (tenant/org credentials, subscription/account credentials, resource credentials).
- **Document credential requirements**: in TODO.md, list all credentials needed and their originating source.
- **Avoid cross-environment sharing**: do not reuse credentials across tenants/accounts/environments unless explicitly intended.
- **Pin the credential variable contract**: the Terraform module's `variables.tf` declares credential inputs the deployment workflow exports as environment variables. Both sides must use identical names. Drift between `variables.tf` and the workflow generator is a deploy-blocking error caught by the parity check.
- **Atomic updates across both sides**: a new or renamed credential variable requires updating the workflow generator and the `variables.tf` generation pattern in the same commit. Run the parity check to verify alignment before merging.
- **Cross-reference from the orchestrator**: the orchestrator's workflow-generation step must reference this credential variable contract, so an agent generating the workflow without loading the full Terraform skill still produces names that align with `variables.tf`.

## Output Strategy

Outputs expose infrastructure properties to downstream systems. Design outputs carefully:

- **Resource identifiers**: export full resource IDs or ARNs (not just names) for CLI consumption and role assignments.
- **Service endpoints**: URLs, hostnames, or connection strings for application configuration.
- **Never export secrets**: do not output credentials, API keys, or sensitive values; reference secrets via the secret store instead.
- **Derived values**: export computed names, tags, or resource groupings that consumers depend on.
- **Document assumptions**: comment on output format and required downstream processing.

## Terraform File Structure

Organize Terraform code for clarity and maintainability:

- **`versions.tf`**: provider requirements and Terraform version constraint
- **`providers.tf`**: provider configuration and authentication
- **`variables.tf`**: input variables, grouped by logical domain
- **`locals.tf`**: derived values (names, computed maps)
- **`main.tf`**: resource definitions
- **`outputs.tf`**: exported values for downstream systems
- **`backend.tf` (optional)**: remote backend configuration for state persistence

## Common Error Prevention

The skill's no-iteration policy (Core Principle 7) removes a class of errors that other Terraform codebases hit. The error categories below are the ones that remain across cloud providers.

### Permission Errors (403 Forbidden / equivalent)
**Error**: Provider unable to read accounts, create resources, or perform operations.
**Prevention**:
- Assume the deploying principal may lack baseline permissions.
- Document required roles in TODO.md and README.md.
- For CI/CD, explicitly pass credentials as variables rather than relying on implicit authentication.
- Include a validation step before deployment when possible.

### Identity Creation Restrictions
**Error**: Tenant or organisation policy prevents identity creation (app registration, custom roles, service principals, IAM users).
**Prevention**:
- Do not assume every environment allows identity creation.
- Implement conditional identity provisioning by generating one of two `main.tf` variants at code-generation time (per Core Principle 7): a `create` variant that emits the identity resources, and an `existing` variant that omits them and consumes object IDs as input variables.
- In variables.tf, provide a mode variable and document both paths. The variable controls which variant the generator emits; it does not appear as a conditional in the resulting HCL.
- When reusing existing identities, require explicit object ID or client ID inputs.
- When reusing existing identities, avoid mandatory directory or IAM reads during apply; prefer direct use of provided object IDs.
- Add notes in README.md about restricted-environment workarounds.

### Provider Behavior Mismatches
**Error**: Provider control-plane expects one auth method but data-plane uses another; provider uses legacy auth during resource polling.
**Prevention**:
- Use deployment-safe defaults and make strictness configurable.
- Add comments explaining why a property is set this way.
- Provide variables for post-deployment hardening.
- In README.md, document post-deployment hardening steps under "Optional Security Enhancements".

### Soft-Delete Recovery
**Error**: After destroy, the cloud provider retains the resource in a soft-deleted state. On the next apply, the provider raises a recovery-related error (recovery disabled, or no soft-deleted resource exists when recovery is forced).
**Prevention**:
- Make recovery configurable in provider settings instead of hardcoding one value.
- In CI/CD workflows, detect whether a soft-deleted resource with the target name exists and set the variable per run.
- This avoids both failure modes: recovery-disabled when a deleted resource exists, and "doesn't exist" when recovery is forced but nothing is in soft-delete.

### One-Way Property Update Failures
**Error**: An immutable-once-set property fails on update with messages like "cannot be disabled" or "property is read-only after creation", even when the apparent change is unrelated.

**Root cause**: Some cloud properties are one-way flags. Once set to a particular value, they cannot be reverted. Most Terraform providers send the full property set on every update, not just the changed fields. If a one-way property is omitted from the resource, the provider serialises the implicit default into the update request. The cloud rejects the request as an attempted reversion regardless of what the operator intended to change.

A deeper trap: "deployment-safe default" thinking can mislead the generator into emitting the *reversible* value to make the first deploy easier to undo. This convenience is available on the first deploy only. From the second deploy onward, the same value becomes a deploy blocker because the cloud will not let the modify proceed. The property's true deployment-safe value is the value the resource will *permanently* carry from creation onward.

**Prevention**:
- Always set one-way properties explicitly in the generated resource. Treat them as mandatory, not optional.
- Never omit the argument. Omission causes the provider to send the implicit default on every update.
- Never set the reversible-looking value. Existing resources may already be in the immutable state regardless of how they were provisioned.

### Authorisation Model Mismatches (legacy access policies vs RBAC)
Some cloud resources support more than one authorisation model. Where one model has known recovery and parity problems (e.g. access policies that survive parent recovery and cause "already exists" errors on the next deploy) and another model is cleaner (e.g. RBAC role assignments identified by GUID that do not survive recovery in a conflicting way), the generator MUST emit the cleaner model exclusively. Translate the source article's vocabulary into the cleaner model's equivalents; record the article's vocabulary in SPEC.md, not in `main.tf`.

### State Management (already exists / needs import)

**Error**: A resource with a given ID already exists in the cloud but is not in Terraform's state. Terraform tries to create, the cloud rejects the create because the ID is taken.

This commonly fires for two distinct reasons:

1. **The parent resource is leftover from a prior deploy.** A resource was created in a previous run that left no state. Terraform sees the absence and tries to recreate. Importing the parent resource into state resolves this case.

2. **A child resource preserved itself across a parent recreate.** The parent is recovered from soft-delete or imported, and the recovery brings back *child* resources that were attached when the parent was deleted (policies, ACL rules, locks). Terraform creates the parent cleanly but fails on the first child it tries to create.

**Prevention**:
- Treat `already exists` errors as *resource-specific*, not parent-specific. The error message names the resource address and the cloud resource ID — use both. A recovery handler that imports only the parent will not resolve the same error on child resources.
- After recovering a parent from soft-delete, the recovery handler MUST expect child conflicts if legacy children exist. The handler enumerates and imports each preserved child individually by Terraform resource address and cloud resource ID — or the operator deletes them out-of-band before reapplying.
- The deployer often cannot prevent child preservation on the cloud side; recovery brings them back. The only options are (a) wait out the soft-delete retention window, or (b) import each preserved child.

### Cross-System Identity Resolution

**Error**: A reference to an identity in one system (cloud directory) fails to resolve in a separate system (workspace, SaaS application, cluster) that maintains its own identity table. Common wording: `<identity-id> doesn't exist`.

**Root cause**: The originating system and the consuming system are separate identity stores. An identity created in one is not automatically visible to the other. The consuming system resolves references against its own table. If the identity has not been registered there, the lookup fails. The identity exists; the consuming system just can't see it.

**Prevention**: See `## Required Outputs` above. The required-output rule for cross-system identity bridging prevents this error from occurring in the first place. The reactive prevention here is to enumerate every system the identity will be referenced from, and confirm a matching registration exists for each.

## Pre-Generation Validation
Before writing Terraform code, validate the generation strategy:

- [ ] **Provider and authentication**: identify target providers and authentication methods.
- [ ] **Permission model**: understand what base permissions are required; document in TODO.md.
- [ ] **Tenant/environment restrictions**: are there known restrictions on identity creation, custom roles, or directory reads?
- [ ] **Naming strategy**: define semantic components (workload, environment, region) that will drive name derivation.
- [ ] **State persistence**: remote (production) or local/ephemeral (CI/CD)? Document the choice and the cleanup strategy.
- [ ] **Secret handling**: where will credentials come from? Mark secret variables `sensitive = true`.
- [ ] **Error scenarios**: identify which error types from Common Error Prevention apply.
- [ ] **Cross-system identity bridging**: for every identity the module creates, enumerate the downstream systems that will reference it. Each one needs a registration resource.
- [ ] **Credentials and assumptions**: document any assumptions about pre-existing identities, permissions, or resources in variables.tf and TODO.md.

## Implementation Checklist

**Code Quality**
- [ ] Provider versions pinned in `versions.tf`.
- [ ] Variables grouped and documented in `variables.tf`.
- [ ] Sensitive variables marked with `sensitive = true`.
- [ ] Validation rules applied to enum or restricted-value variables.
- [ ] Resource names computed in `locals.tf` (not accepted as input variables).
- [ ] No `for_each` argument in generated Terraform. Verify with `grep`.
- [ ] No `count` argument in generated Terraform. Verify with `grep`.
- [ ] Multiple similar resources (per-instance, per-environment, per-role) written as separate blocks with explicit names following `<resource-type>_<purpose>_<variant>`.
- [ ] Operational-mode variation handled by generating different `main.tf` variants at code-generation time, not by in-HCL conditionals.
- [ ] No hardcoded credentials or secrets in code.
- [ ] Deprecated provider properties avoided.

**Error Prevention and Compatibility**
- [ ] Deployment-safe defaults used for security-sensitive properties, with a migration path to stricter settings.
- [ ] Provider compatibility decisions documented in comments.
- [ ] Conditional identity provisioning implemented if identity creation may be restricted.
- [ ] Required roles and permissions documented in TODO.md and README.md.
- [ ] State persistence strategy documented.
- [ ] Cleanup/teardown strategy provided for ephemeral state scenarios.
- [ ] One-way properties are set explicitly to their permanent value — never omitted, never set to the reversible-looking alternative.
- [ ] Provider property naming matches the version pinned in `required_providers`. Read the version pin before choosing argument forms.
- [ ] Security-tightening properties only appear when the matching supporting infrastructure is in the same configuration; otherwise the looser default is used and hardening is listed in TODO.md.
- [ ] **REQUIRED OUTPUT — cross-system identity registration.** For every identity the module creates, every downstream system that will reference it has a matching registration resource in the same module. Verify by counting originating identity resources and counting registrations per target system; counts must match per system. A mismatch is a generation failure, not a warning.
- [ ] **REQUIRED OUTPUT — provider declarations match registration resources.** Every target system that has registration resources has its provider declared in `versions.tf` and configured in `providers.tf` against the host resource.
- [ ] Every registration resource sources its identity reference from the originating resource — never from a hardcoded value or input variable.
- [ ] Every registration resource declares `depends_on` on the host resource for its target system.
- [ ] No data-source lookups for identities the module is responsible for creating. Registration is a resource, not a discovery.

**Outputs and Documentation**
- [ ] Critical resource identifiers exported as outputs.
- [ ] Service endpoints exported for application configuration.
- [ ] No secrets or credentials in outputs.
- [ ] Comments in code explain non-obvious logic.
- [ ] SPEC.md, TODO.md, README.md created.
- [ ] Terraform syntax validated.