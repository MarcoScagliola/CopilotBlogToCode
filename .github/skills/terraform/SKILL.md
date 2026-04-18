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
Names are critical for resource organization and cost tracking:

- **Derive all resource names from input variables** (workload, environment, region) using consistent conventions in `locals.tf`.
- **Do not accept resource names as direct input variables**; compute them from semantic components.
- **Include region abbreviations** in names (e.g., `rg-myapp-dev-uksouth` or `rg-myapp-dev-uks`).
- **Document naming conventions** in SPEC.md or README.md.

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

### 8. Documentation and Outputs
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
- Add notes in README.md about restricted-tenant workarounds

### Provider Behavior Mismatches (Data Plane Auth, Polling)
**Error**: Provider control-plane expects one auth method but data-plane uses another; provider still uses legacy auth during resource polling.
**Prevention**:
- Use deployment-safe defaults (e.g., enable key-based auth on storage, not disable it) and make strictness configurable
- Add comments in main.tf explaining why a property is set this way (e.g., "Storage shared_access_key_enabled=true because AzureRM provider still polls blob storage with key auth")
- Provide variables for post-deployment hardening (e.g., `storage_shared_key_enabled = var.enable_shared_key` defaulting to true)
- In README.md, document post-deployment hardening steps under "Optional Security Enhancements"

### State Management (Already Exists / Needs Import)
**Error**: Resource already exists in cloud but not in Terraform state; on rerun, Terraform cannot find the resource it created.
**Prevention**:
- Explicitly document state persistence strategy in variables.tf comments and README.md
- If using local state in CI/CD, document the limitation: "State is local and ephemeral; delete cloud resources before rerunning"
- If using remote backend, include backend.tf in the repo and document backend setup in README.md
- Provide a cleanup/teardown strategy in TODO.md (e.g., "Run `terraform destroy` or manually delete resource group before retrying")

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

**Error Prevention and Compatibility**
- [ ] Deployment-safe defaults used for security-sensitive properties (with migration path to stricter settings)
- [ ] Provider compatibility decisions documented in comments
- [ ] Conditional identity provisioning implemented if identity creation may be restricted
- [ ] RBAC/permission requirements documented in TODO.md and README.md
- [ ] State persistence strategy documented (remote backend, local/ephemeral state, or other)
- [ ] Cleanup/teardown strategy provided for ephemeral state scenarios

**Outputs and Documentation**
- [ ] Critical resource identifiers (IDs, ARNs) exported as outputs
- [ ] Service endpoints exported for application configuration
- [ ] No secrets or credentials in outputs
- [ ] Comments in code explain non-obvious logic, especially provider compatibility decisions
- [ ] SPEC.md created with architecture summary and key design decisions
- [ ] TODO.md created with unresolved values, prerequisites, and RBAC requirements
- [ ] README.md created with prerequisites, required credentials, state strategy, and post-deployment steps
- [ ] Terraform syntax validated (`terraform validate or terraform init -backend=false && terraform validate`)

