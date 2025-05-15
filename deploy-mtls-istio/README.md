# mTLS with Istio and AWS Private CA

This module demonstrates how to implement mutual TLS (mTLS) authentication between services using Istio and AWS Private CA.

## Overview

This setup:
1. Installs Istio with AWS Private CA integration
2. Configures Istio to use certificates from AWS Private CA for mTLS
3. Deploys a demo application to demonstrate mTLS communication
4. Enforces mTLS policy for all services in the demo namespace

## Prerequisites

- An EKS cluster with the core AWS Private CA integration set up
- kubectl configured to access your EKS cluster
- Istio CLI (istioctl) installed

## Usage

```bash
./setup-istio-mtls.sh [OPTIONS]
```

### Options

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)

### Example

```bash
./setup-istio-mtls.sh --cluster-name my-eks-cluster --region us-west-2
```

## Testing mTLS

After deployment, you can test mTLS:

1. Test from inside the mesh (should succeed):
   ```
   kubectl exec -it -n istio-demo deploy/client -c client -- curl hello.istio-demo.svc.cluster.local
   ```

2. Create a pod without istio-injection to test mTLS enforcement (should fail):
   ```
   kubectl run test-pod --image=curlimages/curl -n istio-demo --command -- sleep 3650d
   kubectl exec -it test-pod -n istio-demo -- curl hello.istio-demo.svc.cluster.local
   ```

## Architecture

The setup creates:
- Istio control plane configured to use AWS Private CA certificates
- A demo namespace with Istio sidecar injection enabled
- A hello service and a client service to demonstrate mTLS communication
- A PeerAuthentication policy that enforces STRICT mTLS

## Customization

You can modify the manifests in the `manifests` directory to customize the demo application or add your own services with mTLS.