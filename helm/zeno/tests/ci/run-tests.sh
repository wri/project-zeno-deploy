#!/bin/bash
set -euo pipefail

# Function to check if pods are ready
check_pods_ready() {
    local namespace=$1
    local label=$2
    local timeout=300
    local start_time=$(date +%s)

    echo "Waiting for pods with label '$label' in namespace '$namespace' to be ready..."
    while true; do
        if [[ $(($(date +%s) - start_time)) -gt $timeout ]]; then
            echo "Timeout waiting for pods to be ready"
            return 1
        fi

        if kubectl get pods -n "$namespace" -l "$label" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q "False"; then
            echo "Pods not ready yet, waiting..."
            sleep 5
            continue
        fi

        if ! kubectl get pods -n "$namespace" -l "$label" -o jsonpath='{.items[*].status.phase}' | grep -qE "^(Running|Succeeded)$"; then
            echo "Pods not in Running/Succeeded state, waiting..."
            sleep 5
            continue
        fi

        echo "All pods are ready!"
        return 0
    done
}

# Function to check endpoint health
check_endpoint_health() {
    local url=$1
    local timeout=60
    local start_time=$(date +%s)

    echo "Checking health of endpoint: $url"
    while true; do
        if [[ $(($(date +%s) - start_time)) -gt $timeout ]]; then
            echo "Timeout waiting for endpoint to be healthy"
            return 1
        fi

        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
            echo "Endpoint is healthy!"
            return 0
        else
            echo "Endpoint not healthy yet, waiting..."
            sleep 5
        fi
    done
}

# Deploy Zeno chart
echo "Deploying Zeno chart..."
helm upgrade --install zeno ../../zeno \
    -f ../../zeno/values.yaml \
    --set langfuse.postgresql.deploy=false \
    --set langfuse.postgresql.auth.password="test-password" \
    --set langfuse.postgresql.auth.username="postgres" \
    --set langfuse.postgresql.auth.database="langfuse" \
    --set langfuse.postgresql.host="postgresql" \
    --set langfuse.langfuse.nextauth.secret="test-secret" \
    --set langfuse.langfuse.salt="test-salt" \
    --set zeno.secrets.langfuse.INIT_USER_PASSWORD="test-password" \
    --set zeno.secrets.langfuse.INIT_PROJECT_SECRET_KEY="test-key" \
    --set zeno.secrets.langfuse.INIT_PROJECT_PUBLIC_KEY="test-key" \
    --set zeno.db.POSTGRES_USER="postgres" \
    --set zeno.db.POSTGRES_PASSWORD="test-password" \
    --set zeno.db.POSTGRES_HOST="postgresql" \
    --set zeno.db.APP_DB="zeno_db" \
    --wait

# Wait for pods to be ready
check_pods_ready "default" "app=zeno"

# Get service URL
api_service_url=$(kubectl get service zeno-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
streamlit_service_url=$(kubectl get service zeno-streamlit -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Check API health
check_endpoint_health "http://${api_service_url}:8000/health"

# Check Streamlit health
check_endpoint_health "http://${streamlit_service_url}:8501/healthz"

# Basic functionality tests
echo "Running basic functionality tests..."

# Test API endpoints (add specific endpoint tests based on your API)
curl -f "http://${api_service_url}:8000/health"

# Check if database migration job completed successfully
if ! kubectl get job zeno-db-migrate -o jsonpath='{.status.succeeded}' | grep -q "1"; then
    echo "Database migration job failed"
    exit 1
fi

echo "All tests passed successfully!"
