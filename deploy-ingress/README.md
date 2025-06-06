# Deploy TLS-enabled Ingress

This module demonstrates how to deploy a TLS-enabled service to your cluster, behind an AWS Load Balancer.

## Overview

This setup:
1. Installs the NGINX ingress controller
2. Deploys an AWS Network Load Balancer
3. Deploys a demo application to the cluster
4. Automatically provisions a certificate from AWS Private CA
5. Configures the ingress to process and terminate encrypted TLS connections

## Usage

```bash
./deploy-ingress.sh [OPTIONAL PARAMETERS]
```

### Optional Parameters

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)

### Example

```bash
./deploy-ingress.sh --cluster-name my-eks-cluster --region us-east-1
```

## Testing the Ingress

After deployment, the script will output the hostname of the load balancer. You can access the demo application using:

```
https://<load-balancer-hostname>
```

Note: Since the certificate is issued by a private CA, your browser will show a warning. To trust the certificate, you need to import the CA certificate into your trust store.

## Customization

Modify the `manifests/demo-app.yaml` file to customize the demo application or add your own applications.