from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os
import shutil
import time

# Where your Airflow logs are stored (default)
BASE_LOG_FOLDER = "/opt/airflow/logs"
DAYS_TO_KEEP = 2  # Only keep logs from the past 2 days

def cleanup_logs():
    cutoff_time = time.time() - DAYS_TO_KEEP * 24 * 60 * 60
    for root, dirs, files in os.walk(BASE_LOG_FOLDER):
        for name in files:
            filepath = os.path.join(root, name)
            try:
                if os.path.getmtime(filepath) < cutoff_time:
                    os.remove(filepath)
            except Exception as e:
                print(f"Error deleting file {filepath}: {e}")
        # Remove empty directories
        for name in dirs:
            dirpath = os.path.join(root, name)
            try:
                if not os.listdir(dirpath):  # empty
                    shutil.rmtree(dirpath)
            except Exception as e:
                print(f"Error deleting directory {dirpath}: {e}")

default_args = {
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="airflow_log_cleanup",
    start_date=datetime(2025, 10, 1),
    schedule="0 2 * * *",  # Run every day at 2 AM; adjust as needed
    catchup=False,
    default_args=default_args,
    tags=["maintenance", "log_cleanup"],
) as dag:

    clean_logs = PythonOperator(
        task_id="cleanup_logs",
        python_callable=cleanup_logs,
    )
