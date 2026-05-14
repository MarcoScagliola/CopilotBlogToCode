from __future__ import annotations

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion placeholder for secure medallion pattern.")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark.sql(f"CREATE CATALOG IF NOT EXISTS `{args.catalog}`")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{args.catalog}`.`{args.schema}`")
    spark.sql(
        f"""
        CREATE TABLE IF NOT EXISTS `{args.catalog}`.`{args.schema}`.`raw_events`
        USING DELTA
        AS SELECT
          current_timestamp() AS ingested_at,
          'bootstrap' AS source_name,
          1 AS event_count
        """
    )


if __name__ == "__main__":
    main()
