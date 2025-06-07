# EKS Cluster Creation

This module creates an Amazon EKS cluster configured for AWS Private CA integration.

## Overview

The script in this directory creates an EKS cluster using eksctl. The [`cluster.yaml`](cluster.yaml) file can be used to configure the cluster. By default, this script will create an EKS cluster with Auto mode enable. Auto mode simplifies cluster management for compute, storage and networking. In this sample, Auto Mode will automatically create AWS Load Balancers when deploying Ingress manifests.

## Usage

```bash
./create-cluster.sh [OPTIONAL PARAMETERS]
```

### Optional Parameters

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

1. [**Deploy core PKI tooling and AWS Private CA**:](../deploy-core-pki/README.md)
   ```
   ../deploy-core-pki/deploy-core.sh --cluster-name <cluster-name> --region <region>
   ```

2. [**Deploy TLS-enabled ingress**:](../deploy-ingress/README.md)
   ```
   ../deploy-ingress/deploy-ingress.sh --cluster-name <cluster-name> --region <region>
   ```

3. [**Deploy end to end encryption and mTLS with Istio**:](../deploy-mtls-istio/README.md)
   ```
   ../deploy-mtls-istio/setup-istio-mtls.sh --cluster-name <cluster-name> --region <region>
   ```