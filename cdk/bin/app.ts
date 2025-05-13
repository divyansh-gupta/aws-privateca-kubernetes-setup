#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { PrivateCAStack } from '../lib/private-ca-stack';
import { IAMRolesStack } from '../lib/iam-roles-stack';

const app = new cdk.App();

// Get context values
const eksClusterName = app.node.tryGetContext('EksClusterName') || 'aws-pca-k8s-demo';
const region = app.node.tryGetContext('region') || process.env.CDK_DEFAULT_REGION || 'us-east-1';
const account = app.node.tryGetContext('account') || process.env.CDK_DEFAULT_ACCOUNT;
const existingCaArn = app.node.tryGetContext('ExistingCaArn');

// Create environment
const env = { account, region };

// Create stacks
if (!existingCaArn) {
  new PrivateCAStack(app, 'PrivateCAStack', { env });
}

new IAMRolesStack(app, 'IAMRolesStack', { env });

app.synth();