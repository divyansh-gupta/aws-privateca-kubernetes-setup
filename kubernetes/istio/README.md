# Istio mTLS with AWS Private CA

This directory contains configurations for setting up Istio with AWS Private CA for automatic certificate provisioning and mTLS between services.

## Overview

The setup integrates the following components:
- AWS Private CA - provides the root certificate authority
- cert-manager - manages certificate lifecycle
- AWS PCA Issuer - connects cert-manager to AWS Private CA
- Istio - provides service mesh capabilities with mTLS

## Directory Structure

- `base/` - Core Istio and certificate configurations
  - `istio-cluster-issuer.yaml` - ClusterIssuer configuration using AWS PCA
  - `istio-cert.yaml` - Certificate configuration for Istio CA
  - `peer-authentication.yaml` - Istio PeerAuthentication policy for strict mTLS

- `examples/` - Example applications to demonstrate mTLS
  - `demo-app.yaml` - Two services (hello and world) that communicate with each other
  - `client-pod.yaml` - A client pod without Istio sidecar for testing mTLS enforcement

## How It Works

1. AWS Private CA provides the root certificate authority
2. cert-manager requests a certificate from AWS Private CA
3. The certificate is stored as a Kubernetes secret
4. Istio uses this certificate for mTLS between services
5. All pods in the mesh automatically get certificates and establish mTLS connections

## Testing mTLS

You can verify that mTLS is working by:

1. Checking that certificates are properly mounted:
   ```
   kubectl exec -it -n istio-demo deploy/hello -- ls -la /etc/certs
   ```

2. Testing communication between services (should succeed with mTLS):
   ```
   kubectl exec -it -n istio-demo deploy/hello -- curl world.istio-demo.svc.cluster.local
   ```

3. Verifying mTLS is enforced (from client pod without Istio sidecar):
   ```
   kubectl exec -it -n istio-demo client -- curl hello.istio-demo.svc.cluster.local
   ```
   This should fail because the client pod doesn't have the required certificates.

4. Checking the TLS status:
   ```
   istioctl x describe pod hello -n istio-demo
   ```

## Troubleshooting

If you encounter issues:

1. Check that the certificate was issued correctly:
   ```
   kubectl get certificate -n istio-system
   ```

2. Verify Istio sidecar injection is enabled:
   ```
   kubectl get namespace istio-demo --show-labels
   ```

3. Check Istio proxy logs:
   ```
   kubectl logs -n istio-demo deploy/hello -c istio-proxy
   ```

4. Verify mTLS policy:
   ```
   kubectl get peerauthentication -n istio-system
   ```