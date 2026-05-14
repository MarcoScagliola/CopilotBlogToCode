from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gold aggregation placeholder for secure medallion pattern.")
    parser.add_argument("--source-catalog", required=True)
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--target-catalog", required=True)
    parser.add_argument("--target-schema", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{args.target_catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{args.target_catalog}`.`{args.target_schema}`")
    spark.sql(
        f"""
        CREATE OR REPLACE TABLE `{args.target_catalog}`.`{args.target_schema}`.`events_daily`
        USING DELTA
        AS SELECT
          event_date,
          SUM(total_events) AS events_per_day
        FROM `{args.source_catalog}`.`{args.source_schema}`.`events_curated`
        GROUP BY event_date
        """
    )


if __name__ == "__main__":
    main()
