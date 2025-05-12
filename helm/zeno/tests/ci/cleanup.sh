#!/bin/bash
set -euo pipefail

echo "Cleaning up test environment..."

# Uninstall Helm releases
echo "Uninstalling Helm releases..."
helm uninstall zeno || true
helm uninstall support || true
helm uninstall cert-manager || true
helm uninstall ingress-nginx || true
helm uninstall postgresql || true

# Delete k3d cluster
echo "Deleting k3d cluster..."
k3d cluster delete test-cluster || true

echo "Cleanup complete!"
