# mTLS with Istio and AWS Private CA

This module demonstrates how to implement end to end encryption in transit and mutual TLS (mTLS) between services using Istio with AWS Private CA.

## Overview

This setup:
1. Installs Istio to your cluster
2. Configures Istio to use certificates from AWS Private CA for encryption in transit
3. Deploys a demo application to demonstrate encryption in transit and mTLS
4. Enforces mTLS policy for all services in the demo namespace

## Usage

```bash
./setup-istio-mtls.sh [OPTIONAL PARAMETERS]
```

### Optional Parameters

- `--cluster-name`: Name of the EKS cluster (default: aws-pca-k8s-demo)
- `--region`: AWS region (default: us-east-1)

### Example

```bash
./setup-istio-mtls.sh --cluster-name my-eks-cluster --region us-west-2
```

## Testing mTLS

After deployment, you can test mTLS and encryption in transit:

1. Test from inside the mesh (should succeed):
   ```
   kubectl exec -it -n istio-demo deploy/client -c client -- curl hello.istio-demo.svc.cluster.local
   ```

2. Create a pod without istio-injection to test mTLS enforcement (should fail):
   ```
   kubectl run test-pod --image=curlimages/curl -n istio-demo --command -- sleep 3650d
   kubectl exec -it test-pod -n istio-demo -- curl hello.istio-demo.svc.cluster.local
   ```

3. Curl the Load Balancer URL for external access (TLS enabled):"
   ```
   curl -vk https://$GATEWAY_URL
   ```

   Note: The -k flag is used to skip certificate verification in testing. This is because a private certifiate is being used. Do not use this in production.

## Customization

You can modify the manifests in the `manifests` directory to customize the demo application or add your own services with mTLS.