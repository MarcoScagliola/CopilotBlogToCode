import yaml
import glob
import sys

files = glob.glob(".github/workflows/*.yml") + glob.glob("databricks-bundle/**/*.yml", recursive=True)
errors = 0
for f in files:
    try:
        with open(f, "r") as s:
            yaml.safe_load(s)
    except Exception as e:
        print(f"FAIL: {f} - {e}")
        errors += 1
if errors == 0:
    print("PASS: All YAML files parsed successfully.")
    sys.exit(0)
else:
    sys.exit(1)
