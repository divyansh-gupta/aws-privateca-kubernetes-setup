# EKS Cluster Setup for AWS Private CA Integration

This document explains how to set up an Amazon EKS cluster for use with the AWS Private CA integration.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) (configured with appropriate permissions)
- [eksctl](https://eksctl.io/) (version 0.150.0 or later)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)

## Cluster Creation

You can create an EKS cluster using the provided script:

```bash
./scripts/create-cluster.sh [--cluster-name YOUR_CLUSTER_NAME] [--region YOUR_REGION]
```

Or using npm:

```bash
npm run create:cluster -- [--cluster-name YOUR_CLUSTER_NAME] [--region YOUR_REGION]
```

If you don't specify parameters, the script will use default values:
- Cluster name: `aws-pca-k8s-demo`
- Region: `us-west-2` (or the value of your `AWS_REGION` environment variable)

## Cluster Configuration

The cluster is created with the following configuration:

- EKS version 1.32
- API authentication mode
- IAM OIDC provider for service account integration
- EKS Pod Identity Agent addon
- Managed node group with m5.large instances
- Private networking with public and private cluster endpoints
- CloudWatch logging enabled

### Service Accounts

The cluster configuration includes the following service accounts:

- `cert-manager` in the `cert-manager` namespace
- `aws-privateca-issuer` in the `aws-privateca-issuer` namespace

These service accounts are configured with the necessary IAM permissions for the AWS Private CA integration.

## Next Steps

After creating the cluster, you can proceed with the AWS Private CA integration:

1. Deploy the core AWS Private CA integration:
   ```bash
   ./scripts/deploy-core.sh --cluster-name YOUR_CLUSTER_NAME --region YOUR_REGION
   ```

2. Deploy the NGINX ingress controller with TLS:
   ```bash
   ./scripts/deploy-ingress.sh --cluster-name YOUR_CLUSTER_NAME --region YOUR_REGION
   ```

3. (Optional) Deploy the IAM Roles Anywhere integration:
   ```bash
   ./scripts/deploy-roles-anywhere.sh --cluster-name YOUR_CLUSTER_NAME --region YOUR_REGION
   ```

## Customizing the Cluster

If you need to customize the cluster configuration, you can edit the `cluster.yaml` file before running the create script. The file includes comments explaining the various configuration options.

## Troubleshooting

If you encounter issues during cluster creation:

1. Check the eksctl logs for detailed error messages
2. Ensure your AWS CLI is properly configured with sufficient permissions
3. Verify that you have the required service quotas in your AWS account
4. Check that the specified region supports all the required EKS features

## Cleanup

To delete the cluster when you're done:

```bash
eksctl delete cluster --name YOUR_CLUSTER_NAME --region YOUR_REGION
```

This will delete the EKS cluster and all associated resources, including load balancers, security groups, and IAM roles.