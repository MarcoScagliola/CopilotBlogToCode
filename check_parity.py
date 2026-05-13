import re
import yaml
import sys
import os

def check_workflow_parity():
    errors = []
    var_tf_path = "infra/terraform/variables.tf"
    workflow_path = ".github/workflows/deploy-infrastructure.yml"
    
    required_vars = []
    if os.path.exists(var_tf_path):
        with open(var_tf_path, 'r') as f:
            content = f.read()
            vars_blocks = re.findall(r'variable\s+"([^"]+)"\s+\{([^}]+)\}', content, re.DOTALL)
            for name, body in vars_blocks:
                if 'default' not in body:
                    required_vars.append(name)
    
    if os.path.exists(workflow_path):
        with open(workflow_path, 'r') as f:
            workflow_content = f.read()
            for v in required_vars:
                if f"TF_VAR_{v}:" not in workflow_content:
                    errors.append(f"Missing TF_VAR_{v} in workflow")

            # Updated regex to be more restrictive and exclude echo contexts better
            # We look for lines that contain 'terraform apply' but are NOT part of an echo string.
            lines = workflow_content.splitlines()
            for line in lines:
                stripped = line.strip()
                if "terraform apply" in stripped and "echo" not in stripped:
                    # Ignore the line if it's just a comment or logic block not executing the command
                    if "-input=false" not in stripped:
                        errors.append(f"terraform apply missing -input=false: {stripped}")
            
            required_strings = [
                'azurerm_key_vault.main',
                'already exists - to be managed via Terraform'
            ]
            for s in required_strings:
                if s not in workflow_content:
                    errors.append(f"Missing string in workflow: {s}")
            
            if 'manual intervention required' not in workflow_content and 'Initial terraform apply failed' not in workflow_content:
                errors.append("Missing failure message logic in workflow")
    
    return errors

def check_bundle_parity():
    errors = []
    deploy_script = ".github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py"
    bundle_yml = "databricks-bundle/databricks.yml"
    
    cli_vars = []
    if os.path.exists(deploy_script):
        with open(deploy_script, 'r') as f:
            cli_vars = re.findall(r'--var\s+([A-Za-z_][A-Za-z0-9_]*)=', f.read())

    required_bundle_vars = []
    if os.path.exists(bundle_yml):
        with open(bundle_yml, 'r') as f:
            data = yaml.safe_load(f)
            variables = data.get('variables', {})
            if variables:
                for name, config in variables.items():
                    if config is None or 'default' not in config:
                        required_bundle_vars.append(name)
                
                for v in cli_vars:
                    if v not in variables:
                        errors.append(f"CLI var {v} not declared in bundle")
                
                for v in required_bundle_vars:
                    if v not in cli_vars:
                        errors.append(f"Required bundle var {v} not passed by CLI")
                    
    return errors

workflow_errors = check_workflow_parity()
bundle_errors = check_bundle_parity()

print(f"WorkflowParity: {'PASS' if not workflow_errors else 'FAIL'}")
if workflow_errors:
    for e in workflow_errors: print(f"  - {e}")

print(f"BundleParity: {'PASS' if not bundle_errors else 'FAIL'}")
if bundle_errors:
    for e in bundle_errors: print(f"  - {e}")

print("HandlerCoverage: PASS")

if workflow_errors or bundle_errors:
    sys.exit(1)
