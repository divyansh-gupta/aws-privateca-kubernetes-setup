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

echo "=== Deploying TLS-enabled Ingress ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# Set AWS_REGION for AWS CLI commands
export AWS_REGION=$REGION

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=ingress-nginx

# Wait for the load balancer to be provisioned
echo "Waiting for the load balancer to be provisioned..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get the load balancer hostname
LOAD_BALANCER_HOSTNAME=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Load balancer hostname: $LOAD_BALANCER_HOSTNAME"

# Deploy a demo application
echo "Deploying a demo application..."
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -

export LOAD_BALANCER_HOSTNAME=$LOAD_BALANCER_HOSTNAME
envsubst < "$(dirname "$0")/../kubernetes/ingress/demo-app.yaml" | kubectl apply -f -

echo "=== Deployment Complete ==="
echo "Your TLS-enabled ingress is now available at:"
echo "https://${LOAD_BALANCER_HOSTNAME}"
echo ""
echo "Note: Since the certificate is issued by a private CA, your browser will show a warning."
echo "To trust the certificate, you would need to import the CA certificate into your trust store."