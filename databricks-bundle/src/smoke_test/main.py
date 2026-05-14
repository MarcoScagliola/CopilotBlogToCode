from __future__ import annotations

import argparse


def _table_count(table_name: str) -> int:
    result = spark.sql(f"SELECT COUNT(*) AS c FROM {table_name}").collect()
    return int(result[0]["c"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate medallion table availability after deployment.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", required=True, type=int)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    tables = [
        f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`raw_events`",
        f"`{args.silver_catalog}`.`{args.silver_schema}`.`events_curated`",
        f"`{args.gold_catalog}`.`{args.gold_schema}`.`events_daily`",
    ]

    for table_name in tables:
        if _table_count(table_name) < args.min_row_count:
            raise ValueError(f"Smoke test failed for table {table_name}")


if __name__ == "__main__":
    main()
