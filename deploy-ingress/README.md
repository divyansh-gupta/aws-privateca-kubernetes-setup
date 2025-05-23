# TLS-enabled Ingress with AWS Private CA

This module demonstrates how to set up a TLS-enabled NGINX ingress controller that uses certificates from AWS Private CA.

## Overview

This setup:
1. Installs the NGINX ingress controller
2. Configures it with an AWS Network Load Balancer if using EKS Auto Mode or the AWS Load Balancer Controller
3. Deploys a demo application with TLS-enabled ingress
4. Automatically provisions a certificate from AWS Private CA

## Prerequisites

- An EKS cluster with the core AWS Private CA integration set up
- EKS Auto Mode or the AWS Load Balancer Controller installed on the cluster
- kubectl
- Helm

## Usage

```bash
./deploy-ingress.sh [OPTIONS]
```

### Options

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)

### Example

```bash
./deploy-ingress.sh --cluster-name my-eks-cluster --region us-west-2
```

## Testing the Ingress

After deployment, the script will output the hostname of the load balancer. You can access the demo application using:

```
https://<load-balancer-hostname>
```

Note: Since the certificate is issued by a private CA, your browser will show a warning. To trust the certificate, you need to import the CA certificate into your trust store.

## Architecture

The setup creates:
- An NGINX ingress controller in the `ingress-nginx` namespace
- A demo application with an Ingress resource that requests a certificate from AWS Private CA
- A TLS-enabled endpoint accessible via HTTPS

## Customization

You can modify the `manifests/demo-app.yaml` file to customize the demo application or add your own applications with TLS-enabled ingress.