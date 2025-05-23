# Core AWS Private CA Integration with Kubernetes

This module sets up the core integration between AWS Private CA and Kubernetes using cert-manager and the AWS PCA Issuer.

## Overview

This setup:
1. Creates an AWS Private CA (or uses an existing one)
2. Configures IAM roles for Kubernetes to access AWS Private CA
3. Installs cert-manager in the Kubernetes cluster
4. Installs the AWS PCA Issuer
5. Creates a ClusterIssuer resource that connects to AWS Private CA

## Prerequisites
- An EKS cluster
- AWS CLI
- eksctl
- kubectl

## Usage

```bash
./deploy-core.sh [OPTIONS]
```

### Options

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)
- `--existing-ca-arn`: ARN of an existing AWS Private CA (optional)

### Examples

Create a new AWS Private CA and configure the integration:
```bash
./deploy-core.sh --cluster-name my-eks-cluster --region us-west-2
```

Use an existing AWS Private CA:
```bash
./deploy-core.sh --cluster-name my-eks-cluster --region us-west-2 --existing-ca-arn arn:aws:acm-pca:us-west-2:123456789012:certificate-authority/12345678-1234-1234-1234-123456789012
```

## Testing the Integration

After deployment, you can test the integration by creating a certificate:

```bash
kubectl apply -f manifests/example-certificate.yaml
```

Check the status of the certificate:
```bash
kubectl get certificate example-cert
```

## Next Steps

After setting up the core integration, you can:

1. Deploy the NGINX ingress controller with TLS:
   ```
   ../deploy-ingress/deploy-ingress.sh --cluster-name <cluster-name> --region <region>
   ```

2. Deploy mTLS for your pods with Istio:
   ```
   ../deploy-mtls-istio/setup-istio-mtls.sh --cluster-name <cluster-name> --region <region>
   ```