#!/bin/bash
set -euo pipefail

# Default values
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}

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

echo "=== Creating EKS Cluster for AWS Private CA Integration ==="
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
export AWS_REGION=$REGION

echo "Creating EKS cluster (this may take 15-20 minutes)..."
eksctl create cluster -f "$(dirname "$0")/cluster.yaml"

echo "Verifying cluster access..."
kubectl get nodes
kubectl cluster-info

echo "=== EKS Cluster Creation Complete ==="
echo "Your EKS cluster '$CLUSTER_NAME' is now ready for AWS Private CA integration."
echo ""
echo "Next steps:"
echo "1. Deploy the core AWS Private CA integration:"
echo "   ./deploy-core-pki/deploy-core.sh --cluster-name $CLUSTER_NAME --region $REGION"
echo ""
echo "2. (Optional) Deploy the NGINX ingress controller with TLS:"
echo "   ./deploy-ingress/deploy-ingress.sh --cluster-name $CLUSTER_NAME --region $REGION"
echo ""
echo "3. (Optional) Deploy mTLS for your pods with Istio:"
echo "   ./deploy-mtls-istio/setup-istio-mtls.sh --cluster-name $CLUSTER_NAME --region $REGION"