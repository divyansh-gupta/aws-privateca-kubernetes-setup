# EKS Cluster Creation for AWS Private CA Integration

This module creates an Amazon EKS cluster configured for AWS Private CA integration.

## Overview

The script in this directory creates an EKS cluster using eksctl with the appropriate IAM roles and configurations needed for the AWS Private CA integration.

## Usage

```bash
./create-cluster.sh [OPTIONS]
```

### Options

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region to deploy to (default: us-east-1)

### Example

```bash
./create-cluster.sh --cluster-name my-eks-cluster --region us-west-2
```

## Configuration

The cluster configuration is defined in `cluster.yaml`. You can modify this file to customize:

- Node instance types
- Kubernetes version
- VPC configuration
- Node group settings

## Next Steps

After creating the cluster, you can:

1. Deploy the core AWS Private CA integration:
   ```
   ../deploy-core-pki/deploy-core.sh --cluster-name <cluster-name> --region <region>
   ```

2. Deploy the NGINX ingress controller with TLS:
   ```
   ../deploy-ingress/deploy-ingress.sh --cluster-name <cluster-name> --region <region>
   ```

3. Deploy mTLS for your pods with Istio:
   ```
   ../deploy-mtls-istio/setup-istio-mtls.sh --cluster-name <cluster-name> --region <region>
   ```