#!/bin/bash
set -euo pipefail

# Default values
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --cluster-name)
      CLUSTER_NAME="$2"
      shift
      shift
      ;;
    --region)
      REGION="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== Setting up Istio with AWS Private CA for mTLS ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

# Apply the Istio configurations
echo "Applying Istio configurations..."
envsubst < kubernetes/istio/base/istio-cert.yaml | kubectl apply -f -
kubectl wait --for=condition=Ready certificate istio-ca -n istio-system --timeout=60s

# Install Istio core components using the cert-manager generated certificate
istioctl install --set profile=minimal \
  --set meshConfig.caCertificates[0].secretName=istio-ca-key-pair \
  --set meshConfig.trustDomainAliases[0]="cluster.local" \
  -y

# Create and label namespace for demo
echo "Creating demo namespace..."
kubectl create namespace istio-demo
kubectl label namespace istio-demo istio-injection=enabled

# Deploy the example application
echo "Deploying example application..."
kubectl apply -f kubernetes/istio/examples/demo-app.yaml

# Apply mTLS policy
kubectl apply -f kubernetes/istio/base/peer-authentication.yaml

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello -n istio-demo --timeout=120s
kubectl wait --for=condition=Ready pod -l app=client -n istio-demo --timeout=120s

echo "Setup complete! You can now test mTLS:"
echo "1. Test from inside the mesh (should succeed):"
echo "kubectl exec -it -n istio-demo deploy/client -c client -- curl hello.istio-demo.svc.cluster.local"
echo ""
echo "2. Create a pod without istio-injection to test mTLS enforcement (should fail):"
echo "kubectl run test-pod --image=curlimages/curl -n istio-demo --command -- sleep 3650d"
echo "kubectl exec -it test-pod -n istio-demo -- curl hello.istio-demo.svc.cluster.local"
