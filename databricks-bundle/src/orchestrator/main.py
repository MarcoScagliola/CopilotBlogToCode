import argparse
import json

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Orchestrator checkpoint task")
    parser.add_argument("--bronze-table", required=True)
    parser.add_argument("--silver-table", required=True)
    parser.add_argument("--gold-table", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    summary = {
        "bronze_table": args.bronze_table,
        "bronze_count": spark.table(args.bronze_table).count(),
        "silver_table": args.silver_table,
        "silver_count": spark.table(args.silver_table).count(),
        "gold_table": args.gold_table,
        "gold_count": spark.table(args.gold_table).count(),
    }

    print("Orchestrator checkpoint summary:")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()