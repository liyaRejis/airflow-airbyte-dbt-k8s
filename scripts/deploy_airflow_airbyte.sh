#!/bin/bash
set -e

echo "🎡 Adding Helm repo for Airbyte..."
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update

echo "🚀 Installing Airbyte via Helm..."
helm upgrade --install airbyte airbyte/airbyte -n airbyte -f C:\Users\USER\Downloads\airflow-airbyte-dbt-k8s\helm-values\airbyte-values.yaml 

echo "🌬️ Installing Airflow via Helm..."
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm upgrade --install airflow apache-airflow/airflow -n airflow -f  \airflow-airbyte-dbt-k8s\helm-values\airbyte-values.yaml 

echo "🔐 Creating dbt credentials secret..."
kubectl create secret generic dbt-credentials -n airflow \
  --from-literal=DB_USER=<DB_USER> \
  --from-literal=DB_PASSWORD=<DB_PASSWORD> \
  --from-literal=DB_HOST=<ACTUAL_DB_HOST> \
  --from-literal=DB_NAME=<DB_NAME> \
  --from-literal=DB_SCHEMA=<DB_SCHEMA> || echo "Secret already exists"

echo "🔍 Checking pod statuses..."
kubectl get pods -n airflow
kubectl get pods -n airbyte
kubectl get svc -n airflow
kubectl get svc -n airbyte 

echo "🌐 Airflow Web UI: http://localhost:30808"
echo "🌐 Airbyte Web UI: http://localhost:31764"
echo "👤 Username Airflow: admin | 🔑 Password: admin"
echo "👤 Username Airbyte: airbyte | 🔑 Password: password"

echo "✅ Airflow & Airbyte deployment complete!"



# Validate Airflow DAGs
# kubectl exec -it $(kubectl get pod -n airflow -l component=scheduler -o jsonpath="{.items[0].metadata.name}") -n airflow -- /bin/bash -c "
#     ls /opt/airflow/dags && \
#     airflow dags list && \
#     airflow dags list-import-errors && \
#     airflow dags reserialize && \
#     airflow dags reserialize && \
# "

# # Restart scheduler if needed
# kubectl rollout restart deployment airflow-scheduler -n airflow
