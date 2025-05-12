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

echo "=== Creating EKS Cluster for AWS Private CA Integration ==="
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"

# Set AWS_REGION for AWS CLI commands
export AWS_REGION=$REGION

# Update the cluster.yaml file with the provided cluster name and region
echo "Updating cluster configuration..."
sed -i.bak "s/name: aws-pca-k8s-demo/name: $CLUSTER_NAME/" "$(dirname "$0")/../cluster.yaml"
sed -i.bak "s/region: us-west-2/region: $REGION/" "$(dirname "$0")/../cluster.yaml"
rm "$(dirname "$0")/../cluster.yaml.bak"

# Create the EKS cluster
echo "Creating EKS cluster (this may take 15-20 minutes)..."
eksctl create cluster -f "$(dirname "$0")/../cluster.yaml"

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Verify cluster
echo "Verifying cluster..."
kubectl get nodes
kubectl cluster-info

echo "=== EKS Cluster Creation Complete ==="
echo "Your EKS cluster '$CLUSTER_NAME' is now ready for AWS Private CA integration."
echo ""
echo "Next steps:"
echo "1. Deploy the core AWS Private CA integration:"
echo "   ./scripts/deploy-core.sh --cluster-name $CLUSTER_NAME --region $REGION"
echo ""
echo "2. Deploy the NGINX ingress controller with TLS:"
echo "   ./scripts/deploy-ingress.sh --cluster-name $CLUSTER_NAME --region $REGION"
echo ""
echo "3. (Optional) Deploy the IAM Roles Anywhere integration:"
echo "   ./scripts/deploy-roles-anywhere.sh --cluster-name $CLUSTER_NAME --region $REGION"