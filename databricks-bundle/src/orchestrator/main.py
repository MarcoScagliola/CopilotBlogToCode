from datetime import datetime


def main():
    print(f"Orchestrator checkpoint: {datetime.utcnow().isoformat()}Z")
    print("Layer job ordering is managed by run_job_task dependencies in resources/jobs.yml")


if __name__ == "__main__":
    main()
