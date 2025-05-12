/**
 * Configuration for the AWS Private Certificate Authority
 */
export interface CAConfig {
  type: string;
  keyAlgorithm: string;
  signingAlgorithm: string;
  subject: {
    commonName: string;
    organization?: string;
    organizationalUnit?: string;
    country?: string;
    state?: string;
    locality?: string;
  };
  validityDays: number;
}

/**
 * Default CA configuration for the AWS Private CA integration
 */
export const DEFAULT_CA_CONFIG: CAConfig = {
  type: 'ROOT',
  keyAlgorithm: 'RSA_2048',
  signingAlgorithm: 'SHA256WITHRSA',
  subject: {
    commonName: 'EKS-PCA-Root',
    organization: 'Example Organization',
    country: 'US',
  },
  validityDays: 365,
};