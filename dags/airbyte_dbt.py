from airflow import DAG
from kubernetes.client import V1EnvFromSource, V1SecretEnvSource
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from datetime import datetime, timedelta

default_args = {
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='dbt',
    start_date=datetime(2025, 10, 1),
    schedule=None,
    catchup=False,
    default_args=default_args,
    tags=['dbt']
) as dag:

    # Define a function to create a dbt run operator for a given folder/Folders
    def dbt_run_operator(folder, task_id=None, arguments=None):
        if arguments is None:
            arguments = ['run', '--select', folder]
        return KubernetesPodOperator(
            task_id=task_id or f'dbt_run_{folder.replace("/", "_")}',
            name=f'dbt-{folder.replace("/", "-")}',
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

    # Set dependencies serially
    hr >> staff 
