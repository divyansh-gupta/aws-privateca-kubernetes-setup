#!/bin/bash
set -euo pipefail

echo "=== Uninstalling Istio ==="

# Clean up demo applications first
echo "Removing demo applications..."
kubectl delete -f kubernetes/istio/examples/demo-app.yaml --ignore-not-found

# Remove Istio configurations
echo "Removing Istio configurations..."
kubectl delete -f kubernetes/istio/base/peer-authentication.yaml --ignore-not-found
kubectl delete certificate istio-ca -n istio-system --ignore-not-found
kubectl delete -f kubernetes/istio/base/istio-cert.yaml --ignore-not-found

# Delete the namespace
echo "Removing istio-demo namespace..."
kubectl delete namespace istio-demo --ignore-not-found

# # Uninstall Istio
echo "Uninstalling Istio control plane..."
istioctl uninstall --purge -y

# Remove Istio namespace
echo "Removing istio-system namespace..."
kubectl delete namespace istio-system --ignore-not-found

echo "=== Istio uninstallation complete ==="