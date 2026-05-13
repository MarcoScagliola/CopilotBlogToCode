$deployDabPath = ".github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py"
$bundleRoot = "databricks-bundle/databricks.yml"
$resourcesDir = "databricks-bundle/resources"

# 1. Extract variables from deploy_dab.py
$pyContent = Get-Content $deployDabPath -Raw
$bridgeVars = New-Object System.Collections.Generic.HashSet[string]

# Look for keys in OPTIONAL_VARS and REQUIRED_VARS dictionaries/lists
# And also --var key mappings
$patterns = @(
    "['`"]([^'`"]+)['`"]\s*:", # Dict keys
    "['`"]([^'`"]+)['`"]\s*,"  # List items
)

foreach ($pattern in $patterns) {
    [regex]::Matches($pyContent, $pattern) | ForEach-Object {
        $key = $_.Groups[1].Value
        if ($key -match '^[a-z_][a-z0-0_]*$') { $bridgeVars.Add($key) | Out-Null }
    }
}
# Filter bridge vars to those likely to be passed as --var
# (Heuristic: typical names found in DABs)
$bridgeVars = $bridgeVars | Where-Object { $_ -match "cluster_id|job_id|instance_pool|service_principal|resource_id|environment|prefix|workspace" }

# 2. Extract variables from databricks.yml and resources/*.yml
$bundleVars = New-Object System.Collections.Generic.HashSet[string]
$bundleRequiredVars = New-Object System.Collections.Generic.HashSet[string]

function Parse-YamlVars($path) {
    if (Test-Path $path) {
        $content = Get-Content $path
        $inVars = $false
        $currentVar = ""
        foreach ($line in $content) {
            if ($line -match "^variables:") { $inVars = $true; continue }
            if ($inVars) {
                if ($line -match "^\s{2}([a-z_][a-z0-9_]*):") {
                    $currentVar = $matches[1]
                    $bundleVars.Add($currentVar) | Out-Null
                    $bundleRequiredVars.Add($currentVar) | Out-Null # Assume required until default found
                }
                elseif ($line -match "^\S") { $inVars = $false }
                elseif ($currentVar -and ($line -match "default:")) {
                    $bundleRequiredVars.Remove($currentVar) | Out-Null
                }
            }
        }
    }
}

Parse-YamlVars $bundleRoot
Get-ChildItem -Path $resourcesDir -Filter *.yml | ForEach-Object { Parse-YamlVars $_.FullName }

# 3. Compare
$missingInBundle = $bridgeVars | Where-Object { -not $bundleVars.Contains($_) }
$missingInBridge = $bundleRequiredVars | Where-Object { -not $bridgeVars.Contains($_) }

"Bridge Variables: $($bridgeVars -join ', ')"
"Bundle Variables: $($bundleVars -join ', ')"
"Required Bundle Variables: $($bundleRequiredVars -join ', ')"
""

$success = $true
if ($missingInBundle) {
    "FAIL: Variables in script but missing in Bundle: $($missingInBundle -join ', ')"
    $success = $false
}
if ($missingInBridge) {
    "FAIL: Required Bundle variables missing in script: $($missingInBridge -join ', ')"
    $success = $false
}

if ($success) { "PASS: Bundle Parity Validated" }
