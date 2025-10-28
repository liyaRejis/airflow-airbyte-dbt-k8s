# Airflow + Airbyte + dbt on KIND (Helm)

**Author:** Liya Rejis Joseph. 

**Purpose:** Automated data pipeline framework with Airbyte (EL), dbt (T), and Airflow (orchestration) running locally via KIND.

## Features
- Airbyte (CDC-enabled) for ELT ingestion
- Apache Airflow for orchestration (Airflow 3.x)
- dbt for transformations (dbt-core + postgres adapter)
- Example DAGs: trigger sequential Airbyte connections and run dbt jobs in Kubernetes pods
- Helper scripts to build and load images into KIND

## Quickstart (local dev)
1. Clone:
```bash
git clone <your-repo-url>
cd airflow-airbyte-dbt-k8s
```

2. Create KIND cluster and namespaces:
```bash
./scripts/deploy_kind.sh 
```

3. Build images (airflow & dbt) and load into KIND:
```bash
docker build -f docker/airflow.Dockerfile -t airflow:3.0.2-airbyte .
docker build -f docker/dbt.Dockerfile -t dbt-local:latest .
kind load docker-image airflow:3.0.2-airbyte --name airflow-airbyte
kind load docker-image dbt-local:latest --name airflow-airbyte
```

4. Helm deploy:
```bash 
./deploy_airflow_airbyte.sh
```

5. Patch Airbyte service to NodePort (optional):
```bash
kubectl patch svc airbyte-airbyte-server-svc -n airbyte -p '{"spec":{"type":"NodePort","ports":[{"port":8001,"nodePort":31764,"targetPort":"http","protocol":"TCP","name":"http"}]}}'
```

6. Copy DAGs to PVC (local):
```bash
kubectl cp ~/airflow-airbyte-dbt-k8s/dags airflow/airflow-worker-0:/opt/airflow/dags -n airflow
kubectl rollout restart deployment airflow-scheduler -n airflow
```

## Files to customize
- `helm-values/airflow-values.yaml` — NodePort, image tag, DAG PVC claim name
- `helm-values/airbyte-values.yaml` — Airbyte image tag & db persistence
- `dags/*.py` — update CONNECTION_IDS with your Airbyte connection UUIDs
- `docker/dbt.Dockerfile` — copy dbt project or use a git submodule

## Security & secrets
- DO NOT store DB passwords or real credentials in the repo.
- Use `kubectl create secret` for `dbt-credentials` (example in `deploy_airflow_airbyte.sh & scripts/update_dbt.sh`).
- For CI, set GitHub Actions secrets: `KIND_CLUSTER_NAME`, `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (if pushing images).

## License
This project is licensed under the MIT License © 2025 Liya Rejis Joseph.  
Some components (Helm charts, YAML templates, or scripts) are derived from open-source projects such as Airbyte, Airflow, and dbt, and remain under their respective licenses.
