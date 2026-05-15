param(
    [string]$OutputFile = '.github/reports/strict-verification-checklist.json'
)

$ErrorActionPreference = 'Stop'

function Add-CheckResult {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )
    return [pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
    }
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    try {
        $result = & $Action
        if ($result -is [hashtable] -or $result -is [pscustomobject]) {
            return Add-CheckResult -Name $Name -Passed ([bool]$result.passed) -Detail ([string]$result.detail)
        }
        if ($result -is [bool]) {
            return Add-CheckResult -Name $Name -Passed $result -Detail ($(if ($result) { 'ok' } else { 'check returned false' }))
        }
        return Add-CheckResult -Name $Name -Passed $true -Detail 'ok'
    }
    catch {
        return Add-CheckResult -Name $Name -Passed $false -Detail $_.Exception.Message
    }
}

function Run-External {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )
    $output = & $FilePath @Arguments 2>&1
    $code = $LASTEXITCODE
    return [pscustomobject]@{
        code = $code
        output = (($output | Out-String).Trim())
    }
}

$repoRoot = (Get-Location).Path
$bashPath = 'C:/Program Files/Git/bin/bash.exe'
if (-not (Test-Path $bashPath)) {
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        $bashPath = 'bash'
    }
}

$checks = @()

$checks += Invoke-Check -Name 'python_compile_all_generated_py' -Action {
    $pyFiles = @(
        '.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py',
        '.github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py',
        '.github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py',
        '.github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py',
        '.github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py',
        '.github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py',
        'databricks-bundle/src/setup/main.py',
        'databricks-bundle/src/bronze/main.py',
        'databricks-bundle/src/silver/main.py',
        'databricks-bundle/src/gold/main.py',
        'databricks-bundle/src/smoke_test/main.py'
    )
    $r = Run-External -FilePath 'python' -Arguments (@('-m', 'py_compile') + $pyFiles)
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'compiled' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'terraform_init_backend_false' -Action {
    $r = Run-External -FilePath 'terraform' -Arguments @('-chdir=infra/terraform', 'init', '-backend=false')
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'init ok' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'terraform_validate' -Action {
    $r = Run-External -FilePath 'terraform' -Arguments @('-chdir=infra/terraform', 'validate')
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'validate ok' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'yaml_parse_all_generated_yml' -Action {
    $code = "import glob,yaml; files=glob.glob('.github/workflows/*.yml')+glob.glob('databricks-bundle/**/*.yml', recursive=True); [yaml.safe_load(open(f,encoding='utf-8')) for f in files]; print(len(files))"
    $r = Run-External -FilePath 'python' -Arguments @('-c', $code)
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { "parsed files=$($r.output)" } else { $r.output }) }
}

$checks += Invoke-Check -Name 'workflow_parity' -Action {
    $r = Run-External -FilePath $bashPath -Arguments @('-lc', 'sh .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh')
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'parity ok' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'bundle_parity' -Action {
    $r = Run-External -FilePath $bashPath -Arguments @('-lc', 'sh .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh')
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'parity ok' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'handler_coverage' -Action {
    $r = Run-External -FilePath $bashPath -Arguments @('-lc', 'sh .github/skills/blog-to-databricks-iac/scripts/validate_handler_coverage.sh')
    [pscustomobject]@{ passed = ($r.code -eq 0); detail = $(if ($r.code -eq 0) { 'coverage ok' } else { $r.output }) }
}

$checks += Invoke-Check -Name 'templated_not_literal_workflows' -Action {
    $hits = Select-String -Path '.github/workflows/*.yml' -Pattern 'EXAMPLE|PLACEHOLDER|TODO_|myapp|default identifier' -AllMatches
    [pscustomobject]@{ passed = ($hits.Count -eq 0); detail = $(if ($hits.Count -eq 0) { 'no forbidden literals' } else { ($hits | ForEach-Object { $_.Path + ':' + $_.LineNumber + ':' + $_.Line.Trim() }) -join '; ' }) }
}

$checks += Invoke-Check -Name 'interpolation_constraint_databricks_yml' -Action {
    $hits = Select-String -Path 'databricks-bundle/databricks.yml' -Pattern '^\s*(host|profile|auth_type|name):\s*.*\$\{' -AllMatches
    [pscustomobject]@{ passed = ($hits.Count -eq 0); detail = $(if ($hits.Count -eq 0) { 'no interpolation violations' } else { ($hits | ForEach-Object { $_.LineNumber.ToString() + ':' + $_.Line.Trim() }) -join '; ' }) }
}

$checks += Invoke-Check -Name 'cross_artifact_workspace_outputs_bridge' -Action {
    $outputsText = Get-Content 'infra/terraform/outputs.tf' -Raw
    $bridgeText = Get-Content '.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py' -Raw
    $ok = $outputsText.Contains('output "databricks_workspace_url"') -and
          $outputsText.Contains('output "databricks_workspace_resource_id"') -and
          $bridgeText.Contains('databricks_workspace_url') -and
          $bridgeText.Contains('databricks_workspace_resource_id')
    [pscustomobject]@{ passed = $ok; detail = $(if ($ok) { 'workspace outputs and bridge mapping present' } else { 'missing workspace output or bridge key' }) }
}

$checks += Invoke-Check -Name 'feature_completeness_no_partial_vnet_family' -Action {
    $text = Get-Content 'infra/terraform/main.tf' -Raw
    $m = [regex]::Match($text, '(?s)resource\s+"azurerm_databricks_workspace"\s+"main"\s*\{.*?\}')
    if (-not $m.Success) {
        return [pscustomobject]@{ passed = $false; detail = 'workspace resource block not found' }
    }
    $block = $m.Value
    $hasCustom = $block -match 'custom_parameters'
    $hasPublic = $block -match 'public_network_access_enabled'
    $hasNsg = $block -match 'network_security_group_rules_required'
    $count = 0
    if ($hasCustom) { $count += 1 }
    if ($hasPublic) { $count += 1 }
    if ($hasNsg) { $count += 1 }
    $ok = ($count -eq 0) -or ($count -eq 3)
    [pscustomobject]@{ passed = $ok; detail = "custom_parameters=$hasCustom public_network_access_enabled=$hasPublic network_security_group_rules_required=$hasNsg" }
}

$checks += Invoke-Check -Name 'external_dependency_names_documented_in_todo' -Action {
    $required = @('BLG2CODEDEV', 'AZURE_TENANT_ID', 'AZURE_SUBSCRIPTION_ID', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_SP_OBJECT_ID', 'EXISTING_LAYER_SP_CLIENT_ID', 'EXISTING_LAYER_SP_OBJECT_ID')
    $todo = Get-Content 'TODO.md' -Raw
    $missing = @()
    foreach ($r in $required) {
        if (-not $todo.Contains($r)) {
            $missing += $r
        }
    }
    [pscustomobject]@{ passed = ($missing.Count -eq 0); detail = $(if ($missing.Count -eq 0) { 'all dependencies documented' } else { 'missing: ' + ($missing -join ', ') }) }
}

$checks += Invoke-Check -Name 'spec_todo_not_stated_mapping' -Action {
    $specCount = (Select-String -Path 'SPEC.md' -Pattern 'not stated in article' -AllMatches).Matches.Count
    $todoCount = (Select-String -Path 'TODO.md' -Pattern 'Source: SPEC.md' -AllMatches).Matches.Count
    [pscustomobject]@{ passed = ($todoCount -ge $specCount); detail = "spec_not_stated=$specCount todo_spec_sources=$todoCount" }
}

$checks += Invoke-Check -Name 'idempotence_workflow_and_jobs_generators' -Action {
    $targets = @('.github/workflows/validate-terraform.yml', '.github/workflows/deploy-infrastructure.yml', '.github/workflows/deploy-dab.yml', 'databricks-bundle/resources/jobs.yml')
    $before = @{}
    foreach ($f in $targets) {
        $before[$f] = (Get-FileHash -Path $f -Algorithm SHA256).Hash
    }

    [void](Run-External -FilePath 'python' -Arguments @('.github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py', '--workflow-name', 'Validate Terraform', '--github-environment', 'BLG2CODEDEV', '--tenant-secret', 'AZURE_TENANT_ID', '--subscription-secret', 'AZURE_SUBSCRIPTION_ID'))
    [void](Run-External -FilePath 'python' -Arguments @('.github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py', '--workflow-name', 'Deploy Infrastructure', '--tenant-secret', 'AZURE_TENANT_ID', '--subscription-secret', 'AZURE_SUBSCRIPTION_ID', '--client-id-secret', 'AZURE_CLIENT_ID', '--client-secret-secret', 'AZURE_CLIENT_SECRET', '--sp-object-id-secret', 'AZURE_SP_OBJECT_ID', '--default-workload', 'blg', '--default-environment', 'dev', '--default-region', 'uksouth'))
    [void](Run-External -FilePath 'python' -Arguments @('.github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py', '--workflow-name', 'Deploy DAB', '--github-environment', 'BLG2CODEDEV', '--tenant-secret', 'AZURE_TENANT_ID', '--subscription-secret', 'AZURE_SUBSCRIPTION_ID', '--client-id-secret', 'AZURE_CLIENT_ID', '--client-secret-secret', 'AZURE_CLIENT_SECRET'))
    [void](Run-External -FilePath 'python' -Arguments @('.github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py', '--output', 'databricks-bundle/resources/jobs.yml'))

    $changed = @()
    foreach ($f in $targets) {
        $after = (Get-FileHash -Path $f -Algorithm SHA256).Hash
        if ($after -ne $before[$f]) {
            $changed += $f
        }
    }
    [pscustomobject]@{ passed = ($changed.Count -eq 0); detail = $(if ($changed.Count -eq 0) { 'deterministic outputs' } else { 'changed: ' + ($changed -join ', ') }) }
}

$failedChecks = @($checks | Where-Object { -not $_.passed })
$overallPass = ($failedChecks.Count -eq 0)

$report = [ordered]@{
    runTimestampUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    overallPass = $overallPass
    checks = $checks
    summary = [ordered]@{
        passed = @($checks | Where-Object { $_.passed }).Count
        failed = $failedChecks.Count
    }
}

$outAbs = Join-Path $repoRoot $OutputFile
$outDir = Split-Path -Parent $outAbs
if (-not (Test-Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

$json = $report | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($outAbs, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Wrote strict checklist: $OutputFile"
Write-Host "overallPass=$overallPass"
if ($failedChecks.Count -gt 0) {
    Write-Host "failedChecks=$($failedChecks.name -join ', ')"
}

if (-not $overallPass) {
    exit 1
}
