# AWS Private CA Integration with Kubernetes

This sample demonstrates how to integrate AWS Private Certificate Authority (PCA) with Kubernetes to enable secure TLS communications using private certificates.

## Overview

This project provides a complete setup for integrating AWS Private CA with Kubernetes, enabling:

1. **Core PKI Integration** - Set up AWS Private CA as a certificate issuer for your Kubernetes cluster
2. **TLS-enabled Ingress** - Configure NGINX ingress with TLS certificates from AWS Private CA
3. **mTLS with Istio** - Implement mutual TLS authentication between services using Istio and AWS Private CA

## Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl
- eksctl
- Helm v3
- Node.js and npm (for CDK deployment)
- Istio CLI (for mTLS scenario)

## Getting Started

1. **Create an EKS cluster**:
   ```
   ./create-cluster/create-cluster.sh --region us-east-1
   ```

2. **Deploy core PKI integration**:
   ```
   ./deploy-core-pki/deploy-core.sh --region us-east-1
   ```

3. **Deploy TLS-enabled ingress** (optional):
   ```
   ./deploy-ingress/deploy-ingress.sh --region us-east-1
   ```

4. **Deploy mTLS with Istio** (optional):
   ```
   ./deploy-mtls-istio/setup-istio-mtls.sh --region us-east-1
   ```

## Project Structure

- `cdk/` - AWS CDK code for provisioning AWS resources
- `create-cluster/` - Scripts and configs for creating an EKS cluster
- `deploy-core-pki/` - Core AWS Private CA integration with Kubernetes
- `deploy-ingress/` - TLS-enabled ingress with AWS Private CA
- `deploy-mtls-istio/` - mTLS implementation using Istio and AWS Private CA

## Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.