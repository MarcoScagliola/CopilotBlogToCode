import sys
import os
import yaml
import glob
import re
import py_compile

def check_1():
    print("--- Check 1: Compile Python scripts ---")
    scripts = [
        ".github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py",
        "databricks-bundle/src/setup/main.py",
        "databricks-bundle/src/bronze/main.py",
        "databricks-bundle/src/silver/main.py",
        "databricks-bundle/src/gold/main.py",
        "databricks-bundle/src/smoke_test/main.py"
    ]
    results = []
    for s in scripts:
        if os.path.exists(s):
            try:
                py_compile.compile(s, doraise=True)
                results.append(True)
            except Exception as e:
                print(f"Error compiling {s}: {e}")
                results.append(False)
        else:
            print(f"Skipping {s} (file not found)")
            results.append(True)
    return all(results)

def check_4():
    print("--- Check 4: GitHub Workflows YAML ---")
    try:
        files = glob.glob('.github/workflows/*.yml')
        if not files: return False
        for f in files:
            yaml.safe_load(open(f, encoding='utf-8'))
        print('workflows yaml ok')
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def check_5():
    print("--- Check 5: Databricks Bundle YAML ---")
    try:
        files = glob.glob('databricks-bundle/**/*.yml', recursive=True)
        if not files: return True
        for f in files:
            yaml.safe_load(open(f, encoding='utf-8', errors='ignore'))
        print('bundle yaml ok')
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def check_6():
    print("--- Check 6: Logic/Parity Checks ---")
    deploy_infra_path = ".github/workflows/deploy-infrastructure.yml"
    deploy_dab_wf_path = ".github/workflows/deploy-dab.yml"
    
    infra_ok = True
    if os.path.exists(deploy_infra_path):
        with open(deploy_infra_path, 'r', encoding='utf-8') as f:
            infra_content = f.read()
        tf_apply_ok = "-input=false" in infra_content and "terraform apply" in infra_content
        strings_ok = all(s in infra_content for s in ["azurerm_key_vault.main", "already-exists"])
        fail_strings_ok = any(s in infra_content for s in ["manual intervention required", "Initial terraform apply failed"])
        infra_ok = tf_apply_ok and strings_ok and fail_strings_ok
    else:
        print(f"Missing {deploy_infra_path}")
        infra_ok = False

    bundle_ok = True
    if os.path.exists(deploy_dab_wf_path):
        with open(deploy_dab_wf_path, 'r', encoding='utf-8') as f:
            dab_wf_content = f.read()
        
        bundle_yml_path = "databricks.yml"
        if os.path.exists(bundle_yml_path):
            with open(bundle_yml_path, 'r') as f:
                bundle_conf = yaml.safe_load(f)
            variables = bundle_conf.get('variables', {}).keys()
            
            # Check variables passed in the workflow
            vars_in_wf = re.findall(r'--var\s+([a-zA-Z0-9_]+)=', dab_wf_content)
            for v in vars_in_wf:
                if v not in variables:
                    print(f"Variable {v} in workflow not in databricks.yml")
                    bundle_ok = False
    
    return infra_ok and bundle_ok

def check_7():
    print("--- Check 7: Environment check ---")
    files = glob.glob('.github/workflows/*.yml')
    for f in files:
        with open(f, 'r', encoding='utf-8') as stream:
            content = stream.read()
            if 'environment: BLG2CODEDEV' not in content:
                print(f"Missing environment in {f}")
                return False
    return True

def check_8():
    print("--- Check 8: Placeholder check ---")
    patterns = [r'\{[a-z_]+\}', r'<from SPEC\.md', r'<runtime_value_not_stated>']
    found_issue = False
    for filename in ['README.md', 'TODO.md']:
        if not os.path.exists(filename): continue
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
            for p in patterns:
                if re.search(p, content):
                    print(f"Match found in {filename}: {p}")
                    found_issue = True
    return not found_issue

res1 = check_1()
res4 = check_4()
res5 = check_5()
res6 = check_6()
res7 = check_7()
res8 = check_8()

print("\n--- Summary ---")
print(f"Check 1 (Compile): {'PASS' if res1 else 'FAIL'}")
print(f"Check 4 (WF YAML): {'PASS' if res4 else 'FAIL'}")
print(f"Check 5 (Bundle YAML): {'PASS' if res5 else 'FAIL'}")
print(f"Check 6 (Logic): {'PASS' if res6 else 'FAIL'}")
print(f"Check 7 (Env): {'PASS' if res7 else 'FAIL'}")
print(f"Check 8 (Placeholders): {'PASS' if res8 else 'FAIL'}")
