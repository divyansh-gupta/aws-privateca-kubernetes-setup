# Troubleshooting Guide

This guide provides solutions for common issues you might encounter when using the AWS Private CA integration with Kubernetes.

## CDK Deployment Issues

### Error: No credentials found

**Symptom:** CDK deployment fails with an error about missing AWS credentials.

**Solution:**
1. Configure your AWS credentials:
   ```bash
   aws configure
   ```
2. Or set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key
   export AWS_SECRET_ACCESS_KEY=your_secret_key
   export AWS_REGION=your_region
   ```

### Error: Resource already exists

**Symptom:** CDK deployment fails because a resource with the same name already exists.

**Solution:**
1. Use a different stack name:
   ```bash
   cdk deploy -c stackName=my-unique-stack-name
   ```
2. Or remove the existing resources:
   ```bash
   cdk destroy
   ```

## EKS Pod Identity Issues

### Error: Pod Identity Association not found

**Symptom:** Pods cannot assume IAM roles, and you see errors about missing pod identity associations.

**Solution:**
1. Verify the EKS Pod Identity Agent is installed:
   ```bash
   eksctl get addon --cluster your-cluster-name
   ```
2. Create the pod identity association:
   ```bash
   eksctl create podidentityassociation \
     --cluster your-cluster-name \
     --namespace your-namespace \
     --service-account-name your-service-account \
     --role-arn your-role-arn
   ```

### Error: Access denied when assuming role

**Symptom:** Pods cannot assume IAM roles due to access denied errors.

**Solution:**
1. Check the IAM role trust policy:
   ```bash
   aws iam get-role --role-name your-role-name
   ```
2. Ensure the trust policy allows the EKS Pod Identity service principal and has the correct conditions.

## cert-manager Issues

### Error: Certificate not issued

**Symptom:** Certificates remain in a pending state and are not issued.

**Solution:**
1. Check the cert-manager logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```
2. Check the certificate status:
   ```bash
   kubectl describe certificate -n your-namespace your-certificate
   ```
3. Verify the issuer is ready:
   ```bash
   kubectl get awspcaclusterissuer aws-pca-cluster-issuer -o yaml
   ```

### Error: Certificate issued but not trusted

**Symptom:** Certificates are issued but not trusted by clients.

**Solution:**
1. Import the CA certificate into your trust store:
   ```bash
   aws acm-pca get-certificate-authority-certificate \
     --certificate-authority-arn your-ca-arn \
     --output text --query 'Certificate' > ca.crt
   ```
2. Add the CA certificate to your system's trust store.

## AWS PCA Issuer Issues

### Error: Failed to issue certificate

**Symptom:** AWS PCA Issuer fails to issue certificates.

**Solution:**
1. Check the AWS PCA Issuer logs:
   ```bash
   kubectl logs -n aws-privateca-issuer -l app=aws-privateca-issuer
   ```
2. Verify the IAM permissions:
   ```bash
   aws iam simulate-principal-policy \
     --policy-source-arn your-role-arn \
     --action-names acm-pca:IssueCertificate acm-pca:GetCertificate \
     --resource-arns your-ca-arn
   ```

### Error: Certificate request times out

**Symptom:** Certificate requests time out.

**Solution:**
1. Check network connectivity to AWS services.
2. Increase the timeout in the cert-manager configuration.

## Ingress Issues

### Error: Ingress controller cannot access certificates

**Symptom:** Ingress controller reports errors accessing TLS certificates.

**Solution:**
1. Verify the certificate secret exists:
   ```bash
   kubectl get secret -n your-namespace your-tls-secret
   ```
2. Check the ingress controller logs:
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ```
3. Ensure the ingress resource references the correct secret.

### Error: Certificate not valid for domain

**Symptom:** Browser shows certificate errors about domain mismatch.

**Solution:**
1. Ensure the certificate's DNS names match the ingress host:
   ```bash
   kubectl describe certificate -n your-namespace your-certificate
   ```
2. Update the certificate to include the correct domain names.

## IAM Roles Anywhere Issues

### Error: Trust anchor not found

**Symptom:** IAM Roles Anywhere fails with trust anchor not found errors.

**Solution:**
1. Verify the trust anchor exists:
   ```bash
   aws rolesanywhere list-trust-anchors
   ```
2. Ensure the trust anchor is associated with your CA.

### Error: Certificate validation failed

**Symptom:** IAM Roles Anywhere fails to validate certificates.

**Solution:**
1. Verify the certificate is valid and not expired.
2. Ensure the certificate was issued by the CA associated with the trust anchor.
3. Check that the certificate has the required extensions for IAM Roles Anywhere.

## Common Commands for Troubleshooting

### Check cert-manager resources

```bash
# List all certificates
kubectl get certificates -A

# List all certificate requests
kubectl get certificaterequests -A

# List all issuers
kubectl get awspcaclusterissuer,awspcaissuer -A
```

### Check pod identity associations

```bash
# List all pod identity associations
eksctl get podidentityassociation --cluster your-cluster-name

# Describe a specific pod identity association
eksctl describe podidentityassociation \
  --cluster your-cluster-name \
  --namespace your-namespace \
  --service-account-name your-service-account
```

### Check AWS resources

```bash
# List all private CAs
aws acm-pca list-certificate-authorities

# Describe a specific CA
aws acm-pca describe-certificate-authority \
  --certificate-authority-arn your-ca-arn

# List IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `your-cluster-name`)]'
```

If you encounter issues not covered in this guide, please check the AWS documentation or open an issue in the project repository.