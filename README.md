# Sample: Encryption in Transit for Kubernetes

**Note:** Sample code, software libraries, command line tools, proofs of concept, templates, or other related technology are provided as AWS Content or Third-Party Content under the AWS Customer Agreement, or the relevant written agreement between you and AWS (whichever applies). You should not use this AWS Content or Third-Party Content in your production accounts, or on production or other critical data. You are responsible for testing, securing, and optimizing the AWS Content or Third-Party Content, such as sample code, as appropriate for production grade use based on your specific quality control practices and standards. Deploying AWS Content or Third-Party Content may incur AWS charges for creating or using AWS chargeable resources, such as running Amazon EC2 instances or using Amazon S3 storage.

## Overview

This sample demonstrates how to enable end to end encryption in transit on Kubernetes by integrating AWS Private Certificate Authority (PCA) to enable secure TLS communications using private certificates.

This project provides a complete setup via a set of four scripts, each with it's own README.

## Getting Started

1. [**Create an EKS cluster**:](create-cluster/README.md)
   ```
   ./create-cluster/create-cluster.sh
   ```

2. [**Deploy core PKI tooling and AWS Private CA**:](deploy-core-pki/README.md)
Install core PKI encryption tooling and AWS Private CA as a certificate issuer for your Kubernetes cluster.
   ```
   ./deploy-core-pki/deploy-core.sh
   ```

3. [**Deploy TLS-enabled ingress**:](deploy-ingress/README.md)
Demonstrates how to deploy a TLS-enabled service to your cluster, behind a NGINX ingress that uses certificates from AWS Private CA.
   ```
   ./deploy-ingress/deploy-ingress.sh
   ```

4. [**Deploy end to end encryption and mTLS with Istio**:](deploy-mtls-istio/README.md)
Implement end to end encryption in transit and mTLS between services using Istio with AWS Private CA.
   ```
   ./deploy-mtls-istio/setup-istio-mtls.sh
   ```

## Prerequisites
You will need the following pre-installed to use this sample:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Istio CLI](https://github.com/istio/istio)
- [kubectl](https://github.com/kubernetes/kubectl)
- [eksctl](https://github.com/eksctl-io/eksctl)
- [Helm v3](https://github.com/helm/helm)

## Contributing & Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.