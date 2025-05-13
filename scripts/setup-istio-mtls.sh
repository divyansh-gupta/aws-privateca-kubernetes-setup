#!/bin/bash
set -euo pipefail

# Default values
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}
ISTIO_VERSION="master"

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
    --istio-version)
      ISTIO_VERSION="$2"
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
echo "Istio Version: $ISTIO_VERSION"

# Set AWS_REGION for AWS CLI commands
export AWS_REGION=$REGION

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Get CA ARN from CloudFormation stack
CA_ARN=$(aws cloudformation describe-stacks --stack-name PrivateCAStack --query "Stacks[0].Outputs[?OutputKey=='CertificateAuthorityArn'].OutputValue" --output text)
if [ -z "$CA_ARN" ]; then
  echo "Error: Failed to retrieve Certificate Authority ARN from CloudFormation stack"
  echo "Make sure you've run deploy-core.sh first to set up the AWS Private CA"
  exit 1
fi
echo "CA ARN: $CA_ARN"
export CA_ARN
export REGION

# Download and install Istio
echo "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -

# Add Istio binaries to PATH
ISTIO_DIR="$(pwd)/istio-${ISTIO_VERSION}"
export PATH=$ISTIO_DIR/bin:$PATH

# Install Istio with demo profile (includes gateway)
echo "Installing Istio..."
istioctl install --set profile=demo -y

# Create namespace for the demo
kubectl create namespace istio-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace istio-demo istio-injection=enabled

# Apply the Istio configurations
echo "Applying Istio configurations..."
envsubst < kubernetes/istio/base/istio-cluster-issuer.yaml | kubectl apply -f -
envsubst < kubernetes/istio/base/istio-cert.yaml | kubectl apply -f -

# Wait for the certificate to be ready
echo "Waiting for certificate to be ready..."
kubectl wait --for=condition=Ready certificate istio-ca -n istio-system --timeout=120s

# Apply mTLS policy
kubectl apply -f kubernetes/istio/base/peer-authentication.yaml

# Deploy the example applications
echo "Deploying example applications..."
kubectl apply -f kubernetes/istio/examples/demo-app.yaml
kubectl apply -f kubernetes/istio/examples/client-pod.yaml

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello -n istio-demo --timeout=120s
kubectl wait --for=condition=Ready pod -l app=world -n istio-demo --timeout=120s
kubectl wait --for=condition=Ready pod -l app=client -n istio-demo --timeout=120s

echo "=== Setup Complete ==="
echo "Your Istio mesh is now configured with AWS Private CA for mTLS."
echo ""
echo "To verify mTLS is working, run the following commands:"
echo ""
echo "1. Check that certificates are properly mounted:"
echo "   kubectl exec -it -n istio-demo deploy/hello -- ls -la /etc/certs"
echo ""
echo "2. Test communication between services (should succeed with mTLS):"
echo "   kubectl exec -it -n istio-demo deploy/hello -- curl world.istio-demo.svc.cluster.local"
echo ""
echo "3. Verify mTLS is enforced (from client pod without Istio sidecar):"
echo "   kubectl exec -it -n istio-demo client -- curl hello.istio-demo.svc.cluster.local"
echo "   (This should fail because the client pod doesn't have the required certificates)"
echo ""
echo "4. Check the TLS status:"
echo "   istioctl x describe pod hello -n istio-demo"
echo ""
echo "Configuration files are located at:"
echo "  - kubernetes/istio/base/ (Istio and cert-manager configuration)"
echo "  - kubernetes/istio/examples/ (Demo applications)"