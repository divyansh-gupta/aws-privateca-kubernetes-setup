import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as acmpca from 'aws-cdk-lib/aws-acmpca';
import { CAConfig, DEFAULT_CA_CONFIG } from './ca-config';

export interface PrivateCAStackProps extends cdk.StackProps {
  caConfig?: CAConfig;
}

export class PrivateCAStack extends cdk.Stack {
  public readonly caArn: string;
  public readonly certificateAuthority: acmpca.CfnCertificateAuthority;

  constructor(scope: Construct, id: string, props: PrivateCAStackProps) {
    super(scope, id, props);

    // Use provided CA config or default
    const caConfig = props.caConfig || DEFAULT_CA_CONFIG;

    // Create the Certificate Authority
    this.certificateAuthority = new acmpca.CfnCertificateAuthority(this, 'PrivateCA', {
      type: caConfig.type,
      keyAlgorithm: caConfig.keyAlgorithm,
      signingAlgorithm: caConfig.signingAlgorithm,
      subject: {
        commonName: caConfig.subject.commonName,
        organization: caConfig.subject.organization,
        organizationalUnit: caConfig.subject.organizationalUnit,
        country: caConfig.subject.country,
        state: caConfig.subject.state,
        locality: caConfig.subject.locality,
      },
      revocationConfiguration: {
        crlConfiguration: {
          enabled: false,
        },
        ocspConfiguration: {
          enabled: false,
        },
      },
    });

    // Create a certificate for the CA
    const caCertificate = new acmpca.CfnCertificate(this, 'CACertificate', {
      certificateAuthorityArn: this.certificateAuthority.attrArn,
      certificateSigningRequest: this.certificateAuthority.attrCertificateSigningRequest,
      signingAlgorithm: caConfig.signingAlgorithm,
      templateArn: 'arn:aws:acm-pca:::template/RootCACertificate/V1',
      validity: {
        type: 'DAYS',
        value: caConfig.validityDays,
      },
    });

    // Activate the CA
    const caActivation = new acmpca.CfnCertificateAuthorityActivation(this, 'CAActivation', {
      certificateAuthorityArn: this.certificateAuthority.attrArn,
      certificate: caCertificate.attrCertificate,
      status: 'ACTIVE',
    });

    // Set the CA ARN output
    this.caArn = this.certificateAuthority.attrArn;

    // Export the CA ARN
    new cdk.CfnOutput(this, 'CertificateAuthorityArn', {
      value: this.caArn,
      description: 'ARN of the Private Certificate Authority',
      exportName: 'PrivateCAArn',
    });
  }
}