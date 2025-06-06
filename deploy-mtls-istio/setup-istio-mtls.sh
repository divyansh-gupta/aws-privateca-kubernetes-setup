#!/bin/bash
set -euo pipefail

# Default values
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-aws-pca-k8s-demo}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== Setting up Istio with AWS Private CA for End to End Encryption and mTLS ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

eksctl create podidentityassociation --cluster $CLUSTER_NAME --region $REGION \
  --namespace istio-system \
  --create-service-account \
  --service-account-name istio-ingressgateway \
  --permission-policy-arns arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy 2>&1 | grep -v "already exists" || true

sleep 15

echo "Applying Istio configurations..."
envsubst < "$(dirname "$0")/manifests/istio-cert.yaml" | kubectl apply -f -
kubectl wait --for=condition=Ready certificate.cert-manager.io/istio-ca -n istio-system --timeout=60s

echo "Installing Istio with Gateway support..."
istioctl install --set profile=default \
  --set meshConfig.caCertificates[0].secretName=istio-ca-key-pair \
  --set meshConfig.trustDomainAliases[0]="cluster.local" \
  -y

echo "Creating demo namespace..."
kubectl create namespace istio-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace istio-demo istio-injection=enabled

kubectl create namespace test-mtls --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Gateway certificate..."
kubectl apply -f "$(dirname "$0")/manifests/gateway-cert.yaml"
kubectl wait --for=condition=Ready certificate.cert-manager.io/hello-cert -n istio-system --timeout=60s

echo "Applying Gateway configuration..."
kubectl apply -f "$(dirname "$0")/manifests/gateway.yaml"

echo "Deploying example application..."
kubectl apply -f "$(dirname "$0")/manifests/demo-app.yaml"
kubectl apply -f "$(dirname "$0")/manifests/peer-authentication.yaml"

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello -n istio-demo --timeout=120s
kubectl wait --for=condition=Ready pod -l app=client -n istio-demo --timeout=120s

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "1. Testing internal mTLS (should succeed):"
echo "$ kubectl exec -n istio-demo deploy/client -c client -- curl http://hello.istio-demo.svc.cluster.local"
kubectl exec -n istio-demo deploy/client -c client -- curl http://hello.istio-demo.svc.cluster.local
echo ""

echo "2. Testing from outside mesh (should fail):"
echo "$ kubectl exec -n test-mtls test-pod-no-istio -- curl http://hello.istio-demo.svc.cluster.local"
if kubectl exec -n test-mtls test-pod-no-istio -- curl --max-time 5 http://hello.istio-demo.svc.cluster.local; then
    echo "WARNING: Request from outside the mesh succeeded. mTLS might not be enforced correctly."
else
    echo "SUCCESS: Request from outside the mesh failed as expected. mTLS is working correctly!"
fi
echo ""

echo "3. Gateway URL for external access (TLS enabled):"
echo "$ curl -vk https://GATEWAY_URL"
echo ""
echo "Note: The -k flag is used to skip certificate verification in testing."
echo "In production, use proper certificates and remove the -k flag."