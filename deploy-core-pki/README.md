# Extending the AWS Private CA Integration

This guide provides information on how to extend the AWS Private CA integration with Kubernetes for various use cases.

## Using Your Existing Private CA

If you already have a Private CA in AWS, you can use it with this solution:

```bash
./scripts/deploy-core.sh --cluster-name my-cluster --existing-ca-arn arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/12345678-1234-1234-1234-123456789012
```

This will skip the creation of a new CA and use your existing one instead.

## Adding Custom Certificate Issuers

The default deployment creates an `AWSPCAClusterIssuer` that can be used cluster-wide. You can also create namespace-specific issuers:

```yaml
apiVersion: awspca.cert-manager.io/v1beta1
kind: AWSPCAIssuer
metadata:
  name: aws-pca-issuer
  namespace: my-namespace
spec:
  arn: <your-ca-arn>
  region: <your-region>
```

## Creating Certificates with Different Parameters

You can customize the certificates issued by the CA:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: custom-cert
  namespace: default
spec:
  secretName: custom-cert-tls
  duration: 8760h # 1 year
  renewBefore: 720h # 30 days
  commonName: example.com
  dnsNames:
  - example.com
  - www.example.com
  subject:
    organizations:
    - My Organization
    organizationalUnits:
    - My Department
    countries:
    - US
    provinces:
    - California
    localities:
    - San Francisco
  issuerRef:
    name: aws-pca-cluster-issuer
    kind: AWSPCAClusterIssuer
    group: awspca.cert-manager.io
```

## Integrating with Other AWS Services

### AWS App Mesh

You can use the certificates issued by your Private CA with AWS App Mesh for mTLS:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: appmesh-cert
  namespace: appmesh-system
spec:
  secretName: appmesh-cert
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days
  commonName: appmesh.local
  issuerRef:
    name: aws-pca-cluster-issuer
    kind: AWSPCAClusterIssuer
    group: awspca.cert-manager.io
```

Then configure App Mesh to use this certificate for TLS.

### AWS Load Balancer Controller

You can use the certificates with the AWS Load Balancer Controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alb-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: <your-acm-certificate-arn>
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

## Creating Custom Certificate Workflows

### Automatic Certificate Renewal

cert-manager automatically handles certificate renewal, but you can customize the renewal process:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: auto-renew-cert
  namespace: default
spec:
  secretName: auto-renew-cert-tls
  duration: 2160h # 90 days
  renewBefore: 720h # 30 days
  commonName: example.com
  issuerRef:
    name: aws-pca-cluster-issuer
    kind: AWSPCAClusterIssuer
    group: awspca.cert-manager.io
```

### Certificate Approval Workflow

You can implement a certificate approval workflow using cert-manager's CertificateRequest resource:

```yaml
apiVersion: cert-manager.io/v1
kind: CertificateRequest
metadata:
  name: manual-approval-cert
  namespace: default
spec:
  request: <base64-encoded-csr>
  issuerRef:
    name: aws-pca-cluster-issuer
    kind: AWSPCAClusterIssuer
    group: awspca.cert-manager.io
  usages:
  - digital signature
  - key encipherment
  - server auth
```

Then approve the certificate request manually or through automation.

## Advanced Use Cases

### Multi-Tier CA Hierarchy

For a multi-tier CA hierarchy, you can create a subordinate CA:

1. Create a root CA using the CDK stack
2. Create a subordinate CA using the AWS CLI or console
3. Use the subordinate CA ARN in your deployment

### Cross-Account Certificate Issuance

To issue certificates across AWS accounts:

1. Create the CA in account A
2. Create a resource policy that allows account B to issue certificates
3. In account B, use the CA ARN from account A with appropriate IAM roles

### Certificate Transparency Logging

AWS Private CA supports certificate transparency logging. To enable it:

1. Configure your CA with CT logging enabled
2. Use the CA ARN in your deployment

## Troubleshooting Extensions

If you encounter issues with your extensions:

1. Check the cert-manager logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

2. Check the AWS PCA Issuer logs:
   ```bash
   kubectl logs -n aws-privateca-issuer -l app=aws-privateca-issuer
   ```

3. Verify IAM permissions are correct for cross-account or advanced scenarios

4. Check the status of certificate resources:
   ```bash
   kubectl get certificates,certificaterequests -A
   ```