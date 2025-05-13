import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

export interface IAMRolesStackProps extends cdk.StackProps {
}

/**
 * This stack is now simplified as we're using eksctl to create IRSA
 * for the aws-privateca-issuer service account directly.
 */
export class IAMRolesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: IAMRolesStackProps) {
    super(scope, id, props);
  }
}