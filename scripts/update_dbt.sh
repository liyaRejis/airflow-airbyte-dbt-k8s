#!/bin/bash
set -e

# ----------------------------
# Configuration
# ----------------------------
DBT_PARENT_DIR=~/airflow-airbyte-dbt-k8s       # Root folder of the whole repo
DBT_REPO_NAME=dbt                              # Folder name for dbt project
DBT_DIR="$DBT_PARENT_DIR/$DBT_REPO_NAME"
DOCKER_IMAGE=dbt-local:latest
KIND_CLUSTER=airflow-airbyte
AIRFLOW_DEPLOYMENT=airflow
AIRFLOW_NAMESPACE=airflow
DOCKERFILE_PATH="$DBT_PARENT_DIR/docker/dbt.Dockerfile"  # dbt Dockerfile location

# ----------------------------
# 1️⃣ Remove old dbt project if exists
# ----------------------------
if [ -d "$DBT_DIR" ]; then
    echo "Removing old dbt project..."
    rm -rf "$DBT_DIR"
fi

# ----------------------------
# 2️⃣ Clone latest dbt code from Bitbucket
# ----------------------------
echo "Cloning latest dbt code from master..."
git clone airflow-airbyte-dbt-k8s.git "$DBT_PARENT_DIR"

# ----------------------------
# 3️⃣ Create or update profiles.yml
# ----------------------------
PROFILES_FILE="$DBT_DIR/profiles.yml"
echo "Creating/updating profiles.yml at $PROFILES_FILE..."
cat > "$PROFILES_FILE" <<EOF
config:
  partial_parse: true
  printer_width: 120
  send_anonymous_usage_stats: false
  use_colors: true
normalize:
  outputs:
    dev:
      type: postgres
      threads: 8
      host: "{{ env_var('DB_HOST') }}"
      port: 5432
      user: "{{ env_var('DB_USER') }}"
      pass: "{{ env_var('DB_PASSWORD') }}"
      dbname: "{{ env_var('DB_NAME') }}"
      schema: "{{ env_var('DB_SCHEMA') }}"
  target: dev
EOF

# ----------------------------
# 4️⃣ Build Docker image for dbt
# ----------------------------
echo "Building Docker image for dbt..."
docker build -t $DOCKER_IMAGE -f $DOCKERFILE_PATH $DBT_PARENT_DIR

# ----------------------------
# 5️⃣ Load image into KIND cluster
# ----------------------------
echo "Loading image into KIND cluster..."
kind load docker-image $DOCKER_IMAGE --name $KIND_CLUSTER

echo "✅ Done! KIND now has the latest dbt image from Bitbucket staging."
