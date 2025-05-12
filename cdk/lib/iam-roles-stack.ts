import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

export interface IAMRolesStackProps extends cdk.StackProps {
  eksClusterName: string;
  caArn: string;
}

/**
 * This stack is now simplified as we're using eksctl to create IRSA
 * for the aws-privateca-issuer service account directly.
 */
export class IAMRolesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: IAMRolesStackProps) {
    super(scope, id, props);

    // Export the CA ARN for reference
    new cdk.CfnOutput(this, 'CaArn', {
      value: props.caArn,
      description: 'ARN of the Certificate Authority',
      exportName: 'CaArn',
    });
  }
}