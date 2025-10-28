from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import time

# -----------------------------
# Configuration
# -----------------------------
AIRBYTE_API_URL = "http://airbyte-airbyte-server-svc.airbyte.svc.cluster.local:8001/api/v1"

# List of Airbyte connection IDs in the order to run
CONNECTION_IDS = [
    # Replace with your connection UUIDs
    "14427ec1-221e-4f90-8a01-43b0f666666a"
]

# -----------------------------
# Functions
# -----------------------------

def trigger_and_wait_connection(connection_id):
    """
    Trigger an Airbyte connection sync and wait until it completes.
    """
    # Trigger sync
    trigger_resp = requests.post(
        f"{AIRBYTE_API_URL}/connections/sync",
        json={"connectionId": connection_id}
    )
    trigger_resp.raise_for_status()
    job_id = trigger_resp.json()["job"]["id"]
    print(f"Triggered connection {connection_id}, job_id: {job_id}")

    # Poll until job completes
    while True:
        status_resp = requests.post(f"{AIRBYTE_API_URL}/jobs/get", json={"id": job_id})
        status_resp.raise_for_status()
        status = status_resp.json()["job"]["status"]
        print(f"Job {job_id} status: {status}")

        if status == "succeeded":
            print(f"Connection {connection_id} completed successfully!")
            break
        elif status == "failed":
            raise Exception(f"Connection {connection_id} failed!")
        time.sleep(10)  # wait before next poll

# -----------------------------
# DAG Definition
# -----------------------------
default_args = {
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    dag_id="airbyte_sync_sequential",
    start_date=datetime(2025, 10, 1),
    schedule=None,
    catchup=False,
    default_args=default_args
) as dag:

    previous_task = None

    # Create a PythonOperator for each connection
    for conn_id in CONNECTION_IDS:
        task = PythonOperator(
            task_id=f"sync_airbyte_{conn_id.replace('-', '_')}",
            python_callable=trigger_and_wait_connection,
            op_args=[conn_id]
        )

        # Set sequential dependencies
        if previous_task:
            previous_task >> task
        previous_task = task




# kubectl cp airbyte_trigger_dag.py airflow/airflow-worker-0:/opt/airflow/dags
# kubectl rollout restart deployment airflow-scheduler -n airflow