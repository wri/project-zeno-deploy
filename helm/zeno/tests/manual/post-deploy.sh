#!/bin/bash
set -euo pipefail

# Get environment from argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 staging"
    exit 1
fi

ENVIRONMENT=$1
echo "Running post-deployment checks for $ENVIRONMENT environment..."

# Function to check endpoint health
check_endpoint() {
    local url=$1
    local description=$2
    echo "Checking $description..."
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo "✅ $description is healthy"
        return 0
    else
        echo "❌ $description is not responding"
        return 1
    fi
}

# Function to check pod status
check_pod_status() {
    local label=$1
    local description=$2
    echo "Checking $description pods..."
    
    if kubectl get pods -l "$label" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
        echo "✅ $description pods are healthy"
        return 0
    else
        echo "❌ $description pods are not ready"
        return 1
    fi
}

# Function to check logs for errors
check_pod_logs() {
    local label=$1
    local description=$2
    echo "Checking $description logs for errors..."
    
    if kubectl logs -l "$label" --tail=50 | grep -i "error"; then
        echo "⚠️ Found errors in $description logs"
        return 1
    else
        echo "✅ No errors found in $description logs"
        return 0
    fi
}

# Check kubernetes context
echo "Current context: $(kubectl config current-context)"
read -p "Is this the correct context for $ENVIRONMENT? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please switch to the correct context and try again"
    exit 1
fi

# Testing infrastructure components
echo -e "\n🔍 Testing infrastructure components..."
check_pod_status "app.kubernetes.io/name=ingress-nginx" "Ingress Controller"
check_pod_status "app=cert-manager" "Cert Manager"

# Testing Zeno components
echo -e "\n🔍 Testing Zeno components..."
check_pod_status "app=zeno,component=api" "Zeno API"
check_pod_status "app=zeno,component=streamlit" "Zeno Streamlit"

# Get endpoints from ingress
API_HOST=$(kubectl get ingress zeno-ingress -o jsonpath='{.spec.rules[0].host}')
STREAMLIT_HOST=$(kubectl get ingress zeno-ingress -o jsonpath='{.spec.rules[1].host}')

# Testing endpoints
echo -e "\n🔍 Testing endpoints..."
check_endpoint "https://$API_HOST/health" "API Health Check"
check_endpoint "https://$STREAMLIT_HOST/healthz" "Streamlit Health Check"

# Check database migration status
echo -e "\n🔍 Checking database migration status..."
if kubectl get job zeno-db-migrate -o jsonpath='{.status.succeeded}' | grep -q "1"; then
    echo "✅ Database migration completed successfully"
else
    echo "❌ Database migration job failed or not completed"
    exit 1
fi

# Check logs for potential issues
echo -e "\n🔍 Checking application logs..."
check_pod_logs "app=zeno,component=api" "Zeno API"
check_pod_logs "app=zeno,component=streamlit" "Zeno Streamlit"

echo -e "\n✨ Post-deployment verification complete!"
