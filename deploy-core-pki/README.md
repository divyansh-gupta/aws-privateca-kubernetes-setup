# Deploy core PKI tooling and AWS Private CA

This module installs the core PKI tooling to allow you to setup end to end encryption and utilize TLS for your Kubernetes cluster. It accomplishes this by setting up AWS Private CA as a cert-manager certificate issuer for your cluster. In later modules, you will be able to use this core setup to deploy TLS-enabled services and mTLS between pods.

## Overview

This module executes the following actions:
1. Installs an [AWS Private CA management controller](https://github.com/aws-controllers-k8s/acmpca-controller)
1. Creates an AWS Private CA (or uses an existing one you provide)
2. Configures IAM permissions for Kubernetes to access AWS Private CA
3. Installs cert-manager
4. Installs the [AWS Private CA Connector for Kubernetes](https://github.com/cert-manager/aws-privateca-issuer), a cert-manager issuer
5. Creates a ClusterIssuer resource that allows cert-manager to begin issuing from your AWS Private CA

## Usage

```bash
./deploy-core.sh [OPTIONAL PARAMETERS]
```

### Optional Parameters

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)
- `--existing-ca-arn`: ARN of an existing AWS Private CA (default: script creates a CA)

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
ß
```bash
kubectl apply -f manifests/example-certificate.yaml
```

Check the status of the certificate:
```bash
kubectl get certificate example-cert
```

## Next Steps

After setting up the core integration, you can:

1. [**Deploy TLS-enabled ingress**:](deploy-ingress/README.md)
   ```
   ../deploy-ingress/deploy-ingress.sh --cluster-name <cluster-name> --region <region>
   ```

2. [**Deploy end to end encryption and mTLS with Istio**:](deploy-mtls-istio/README.md)
   ```
   ../deploy-mtls-istio/setup-istio-mtls.sh --cluster-name <cluster-name> --region <region>
   ```