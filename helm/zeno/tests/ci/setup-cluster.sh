#!/bin/bash
set -euo pipefail

# Create k3d cluster
k3d cluster create test-cluster --agents 1 --no-lb --k3s-arg '--disable=traefik@server:0'

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=60s

# Add required helm repos
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install ingress-nginx
echo "Installing ingress-nginx..."
helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.11.3 \
  --namespace ingress-nginx \
  --create-namespace \
  --wait

# Install cert-manager
echo "Installing cert-manager..."
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --version v1.16.1 \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait

# Install PostgreSQL
echo "Installing PostgreSQL..."
helm upgrade --install postgresql bitnami/postgresql \
  --set auth.username=postgres \
  --set auth.password=test-password \
  --set auth.database=zeno_db \
  --set secondary.enabled=false \
  --wait

# Create Langfuse database
echo "Creating Langfuse database..."
kubectl exec -it postgresql-0 -- psql -U postgres -c "CREATE DATABASE langfuse;"

# Install support chart
echo "Installing support chart..."
helm dependency update ../../helm/support
helm upgrade --install support ../../support \
  -f ../../support/values.yaml \
  --namespace support \
  --create-namespace \
  --wait

echo "Cluster setup complete!"
