import yaml
import glob
import sys

files = glob.glob(".github/workflows/*.yml") + glob.glob("databricks-bundle/**/*.yml", recursive=True)
errors = 0
for f in files:
    try:
        with open(f, "r") as stream:
            yaml.safe_load(stream)
    except Exception as e:
        print(f"FAIL: {f} - {e}")
        errors += 1
if errors == 0:
    print("PASS: All YAML files parsed successfully.")
else:
    sys.exit(1)
