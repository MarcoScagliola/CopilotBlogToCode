import yaml
import sys
try:
    with open(sys.argv[1], 'r') as f:
        yaml.safe_load(f)
except Exception as e:
    print(f'Error in {sys.argv[1]}: {e}')
    sys.exit(1)
