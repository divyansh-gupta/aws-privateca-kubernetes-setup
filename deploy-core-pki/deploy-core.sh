#!/bin/bash
set -euo pipefail

REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}
EXISTING_CA_ARN=""

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
export REGION
export AWS_REGION=$REGION

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

if [ -z "$EXISTING_CA_ARN" ]; then
  echo "Installing PCA Controller for Kubernetes..."
  kubectl create namespace ack-system --dry-run=client -o yaml | kubectl apply -f -

  eksctl create podidentityassociation --cluster $CLUSTER_NAME --region $REGION \
    --namespace ack-system \
    --create-service-account \
    --service-account-name ack-acmpca-controller \
    --permission-policy-arns arn:aws:iam::aws:policy/AWSPrivateCAFullAccess 2>&1 | grep -v "already exists" || true

  sleep 15

  RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/acmpca-controller/releases/latest | 
                    jq -r '.tag_name | ltrimstr("v")')

  aws ecr-public get-login-password --region us-east-1 | 
  helm registry login --username AWS --password-stdin public.ecr.aws

  helm upgrade --install \
      --create-namespace \
      -n ack-system \
      ack-acmpca-controller \
      oci://public.ecr.aws/aws-controllers-k8s/acmpca-chart \
      --version=$RELEASE_VERSION \
      --set=aws.region=$AWS_REGION \
      --set=serviceAccount.create=false \
      --set=serviceAccount.name=ack-acmpca-controller

  kubectl apply -f $(dirname "$0")/manifests/private-ca.yaml
  kubectl wait --for=jsonpath='{.status.status}'=ACTIVE certificateauthority root-ca --timeout=120s

  CA_ARN=$(kubectl get certificateauthority root-ca -o json | jq -r '.status.ackResourceMetadata.arn')
else
  CA_ARN=$EXISTING_CA_ARN
fi

echo "CA ARN: $CA_ARN"
export CA_ARN

echo "Installing cert-manager..."
eksctl create addon --name cert-manager --cluster $CLUSTER_NAME --region $REGION
kubectl wait --for=condition=ready pods --all -n cert-manager --timeout=120s

echo "Installing AWS PCA Issuer..."
kubectl create namespace aws-privateca-issuer --dry-run=client -o yaml | kubectl apply -f -

eksctl create podidentityassociation --cluster $CLUSTER_NAME --region $REGION \
  --namespace aws-privateca-issuer \
  --create-service-account \
  --service-account-name aws-privateca-issuer \
  --permission-policy-arns arn:aws:iam::aws:policy/AWSPrivateCAConnectorForKubernetesPolicy 2>&1 | grep -v "already exists" || true

sleep 15

helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer --force-update
helm upgrade --install aws-privateca-issuer awspca/aws-privateca-issuer \
  --namespace aws-privateca-issuer \
  --create-namespace \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-privateca-issuer

kubectl wait --for=condition=ready pods --all -n aws-privateca-issuer --timeout=180s

echo "Creating AWS PCA Cluster Issuer..."
envsubst < "$(dirname "$0")/manifests/cluster-issuer.yaml" | kubectl apply -f -

echo "=== Deployment Complete ==="
echo "Your Kubernetes cluster is now configured with AWS Private CA integration."
echo "You can now issue certificates using the 'aws-pca-cluster-issuer' issuer."
echo "Example:"
echo "  kubectl apply -f $(dirname "$0")/manifests/example-certificate.yaml"