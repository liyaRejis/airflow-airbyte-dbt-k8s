#!/bin/bash
set -e

echo "🔧 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

echo "🧩 Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "🎩 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "🧱 Installing KIND..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/ 

echo "🧱 Checking if KIND cluster exists..."
if ! kind get clusters | grep -q "airflow-airbyte"; then
  echo "🚀 Creating KIND cluster 'airflow-airbyte'..."
  kind create cluster --name airflow-airbyte --config kind/kind-config.yaml
else
  echo "✅ KIND cluster 'airflow-airbyte' already exists."
fi

echo "📦 Switching context to kind-airflow-airbyte..."
kubectl config use-context kind-airflow-airbyte

echo "📦 Creating namespaces..."
kubectl create ns airflow || echo "Namespace 'airflow' already exists"
kubectl create ns airbyte || echo "Namespace 'airbyte' already exists" 

echo "✅ Cluster and namespaces setup complete!" 

echo "✅ Base KIND environment setup complete!"
