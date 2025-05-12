#!/bin/bash
set -euo pipefail

# Default values
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}
EXISTING_CA_ARN=""

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
    --existing-ca-arn)
      EXISTING_CA_ARN="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== AWS Private CA Integration with Kubernetes ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
if [ -n "$EXISTING_CA_ARN" ]; then
  echo "Using existing CA: $EXISTING_CA_ARN"
fi

# Deploy CDK stacks
echo "Deploying AWS resources with CDK..."
cd "$(dirname "$0")/../cdk"

# Set AWS_REGION for AWS CLI commands
export AWS_REGION=$REGION

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Build the CDK app
npm run build

# Bootstrap the CDK environment if needed
echo "Bootstrapping CDK environment in account $AWS_ACCOUNT_ID region $REGION..."
npx cdk bootstrap aws://$AWS_ACCOUNT_ID/$REGION

# Deploy the CDK stacks
if [ -n "$EXISTING_CA_ARN" ]; then
  npx cdk deploy IAMRolesStack \
    --context EksClusterName=$CLUSTER_NAME \
    --context ExistingCaArn=$EXISTING_CA_ARN \
    --context region=$REGION \
    --context account=$AWS_ACCOUNT_ID \
    --require-approval never
else
  npx cdk deploy PrivateCAStack IAMRolesStack \
    --context EksClusterName=$CLUSTER_NAME \
    --context region=$REGION \
    --context account=$AWS_ACCOUNT_ID \
    --require-approval never
fi

# Get outputs from CDK
if [ -z "$EXISTING_CA_ARN" ]; then
  CA_ARN=$(aws cloudformation describe-stacks --stack-name PrivateCAStack --query "Stacks[0].Outputs[?OutputKey=='CertificateAuthorityArn'].OutputValue" --output text)
else
  CA_ARN=$EXISTING_CA_ARN
fi

echo "CA ARN: $CA_ARN"

# Install EKS Pod Identity Agent
echo "Installing EKS Pod Identity Agent..."
eksctl create addon --cluster $CLUSTER_NAME --name eks-pod-identity-agent --force

# Install cert-manager
echo "Installing cert-manager..."
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Install cert-manager with Helm
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --set serviceAccount.create=true \
  --set serviceAccount.name=cert-manager

# Install AWS PCA Issuer
echo "Installing AWS PCA Issuer..."
kubectl create namespace aws-privateca-issuer --dry-run=client -o yaml | kubectl apply -f -

# Create IRSA for AWS PCA Issuer
echo "Creating IAM Role for Service Account (IRSA) for AWS PCA Issuer..."
eksctl create iamserviceaccount \
  --name aws-privateca-issuer \
  --namespace aws-privateca-issuer \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSPrivateCAFullAccess \
  --approve \
  --override-existing-serviceaccounts

helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer --force-update
helm upgrade --install aws-privateca-issuer awspca/aws-privateca-issuer \
  --namespace aws-privateca-issuer \
  --create-namespace \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-privateca-issuer

# Create AWS PCA Cluster Issuer
echo "Creating AWS PCA Cluster Issuer..."
cd "$(dirname "$0")/.."
CLUSTER_ISSUER_PATH="kubernetes/core/cluster-issuer.yaml"
echo $CLUSTER_ISSUER_PATH

echo "Using cluster issuer file at: $CLUSTER_ISSUER_PATH"
envsubst < "$CLUSTER_ISSUER_PATH" | kubectl apply -f -
kubectl wait --for=condition=Ready awspcaclusterissuer aws-pca-cluster-issuer --timeout=120s

echo "=== Deployment Complete ==="
echo "Your Kubernetes cluster is now configured with AWS Private CA integration."
echo "You can now issue certificates using the 'aws-pca-cluster-issuer' issuer."
echo "Example:"
echo "  kubectl apply -f kubernetes/core/example-certificate.yaml"
echo ""
echo "Or view the example certificate file at:"
echo "  kubernetes/core/example-certificate.yaml"