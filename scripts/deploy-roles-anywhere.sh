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

echo "=== Deploying IAM Roles Anywhere Integration ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# Set AWS_REGION for AWS CLI commands
export AWS_REGION=$REGION

# Get the CA ARN
CA_ARN=$(aws cloudformation describe-stacks --stack-name PrivateCAStack --query "Stacks[0].Outputs[?OutputKey=='CertificateAuthorityArn'].OutputValue" --output text)
if [ -z "$CA_ARN" ]; then
  echo "Error: Could not find CA ARN. Make sure you've deployed the core infrastructure."
  exit 1
fi

# Create a trust anchor for IAM Roles Anywhere
echo "Creating IAM Roles Anywhere trust anchor..."
TRUST_ANCHOR_ARN=$(aws rolesanywhere create-trust-anchor \
  --name "${CLUSTER_NAME}-trust-anchor" \
  --source "sourceData={sourceType=AWS_PRIVATE_CA,sourceArn=${CA_ARN}}" \
  --enabled \
  --query 'trustAnchor.trustAnchorArn' \
  --output text)

# Create a role for the application
echo "Creating IAM role for the application..."
APP_ROLE_NAME="${CLUSTER_NAME}-app-role"
APP_ROLE_ARN=$(aws iam create-role \
  --role-name $APP_ROLE_NAME \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "rolesanywhere.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }' \
  --query 'Role.Arn' \
  --output text)

# Add S3 read-only access to the role
aws iam attach-role-policy \
  --role-name $APP_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create a profile for IAM Roles Anywhere
echo "Creating IAM Roles Anywhere profile..."
PROFILE_ARN=$(aws rolesanywhere create-profile \
  --name "${CLUSTER_NAME}-profile" \
  --role-arns $APP_ROLE_ARN \
  --query 'profile.profileArn' \
  --output text)

# Deploy the SPIFFE CSI driver
echo "Deploying SPIFFE CSI driver..."
kubectl create namespace spiffe-csi --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "$(dirname "$0")/../kubernetes/roles-anywhere/spiffe-csi-driver.yaml"

# Deploy a demo application that uses IAM Roles Anywhere
echo "Deploying a demo application that uses IAM Roles Anywhere..."
kubectl create namespace roles-anywhere-demo --dry-run=client -o yaml | kubectl apply -f -

export TRUST_ANCHOR_ARN=$TRUST_ANCHOR_ARN
export PROFILE_ARN=$PROFILE_ARN
export APP_ROLE_ARN=$APP_ROLE_ARN
export REGION=$REGION

envsubst < "$(dirname "$0")/../kubernetes/roles-anywhere/demo-app.yaml" | kubectl apply -f -

echo "=== Deployment Complete ==="
echo "Your IAM Roles Anywhere integration is now deployed."
echo ""
echo "To check the logs of the demo application:"
echo "kubectl logs -n roles-anywhere-demo -l app=roles-anywhere-demo"
echo ""
echo "The demo application should be able to list S3 buckets using temporary credentials"
echo "obtained through IAM Roles Anywhere using the certificate issued by your Private CA."