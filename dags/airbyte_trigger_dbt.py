from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from kubernetes.client import V1EnvFromSource, V1SecretEnvSource
from datetime import datetime, timedelta
import requests
import time

# -----------------------------
# Configuration
# -----------------------------
AIRBYTE_API_URL = "http://airbyte-airbyte-server-svc.airbyte.svc.cluster.local:8001/api/v1"

CONNECTION_IDS = [
    "565eb954-d92e-4080-b9e3-c933f6666f66" 
]

def trigger_and_wait_connection(connection_id):
    trigger_resp = requests.post(
        f"{AIRBYTE_API_URL}/connections/sync",
        json={"connectionId": connection_id}
    )
    trigger_resp.raise_for_status()
    job_id = trigger_resp.json()["job"]["id"]
    print(f"Triggered connection {connection_id}, job_id: {job_id}")

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
        time.sleep(10)

default_args = {
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    dag_id="airbyte_dbt",
    start_date=datetime(2025, 10, 1),
    schedule=None,
    catchup=False,
    default_args=default_args,
    tags=['airbyte', 'dbt']
) as dag:

    # Airbyte sync chain
    previous_task = None
    airbyte_tasks = []
    for conn_id in CONNECTION_IDS:
        task = PythonOperator(
            task_id=f"sync_airbyte_{conn_id.replace('-', '_')}",
            python_callable=trigger_and_wait_connection,
            op_args=[conn_id]
        )
        airbyte_tasks.append(task)
        if previous_task:
            previous_task >> task
        previous_task = task

    # dbt chain
    def dbt_run_operator(folder, task_id=None, arguments=None):
        if arguments is None:
            arguments = ['run', '--select', folder]
        return KubernetesPodOperator(
            task_id=task_id or f'dbt_run_{folder.replace('/', '_')}',
            name=f'dbt-{folder.replace('/', '-')}',
            namespace='airflow',
            image='dbt-local:latest',
            image_pull_policy='IfNotPresent',
            cmds=['dbt'],
            arguments=arguments,
            get_logs=True,
            is_delete_operator_pod=True,
            env_from=[
                V1EnvFromSource(
                    secret_ref=V1SecretEnvSource(name="dbt-credentials")
                )
            ]
        )

    hr = dbt_run_operator("models/hr", "hr")
    staff = dbt_run_operator("models/staff", "staff") 

    # dbt serial chain
    hr >> staff

    # Link Airbyte chain to dbt chain
    # Last Airbyte task triggers first dbt task
    airbyte_tasks[-1] >> hr

