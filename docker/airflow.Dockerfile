# Use Airflow 3.0.2 base image
FROM apache/airflow:3.0.2

# Install Kubernetes provider
RUN pip install apache-airflow-providers-cncf-kubernetes


# docker build -t airflow:3.0.2-airbyte .
# kind load docker-image airflow:3.0.2-airbyte --name airflow-airbyte