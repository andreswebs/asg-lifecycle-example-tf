import {
  SSMClient,
  SendCommandCommandInput,
  SendCommandCommandOutput,
  SendCommandCommand,
  DescribeInstanceInformationCommand,
  DescribeInstanceInformationCommandInput,
  DescribeInstanceInformationCommandOutput,
} from '@aws-sdk/client-ssm';

import {
  EC2Client,
  DescribeInstanceStatusCommand,
  DescribeInstanceStatusCommandInput,
  DescribeInstanceStatusCommandOutput,
} from '@aws-sdk/client-ec2';

import {
  DynamoDBClient,
  ResourceNotFoundException,
} from '@aws-sdk/client-dynamodb';

import {
  DynamoDBDocumentClient,
  GetCommand,
  GetCommandInput,
} from '@aws-sdk/lib-dynamodb';

import { region, dbTableName, dbHashKey } from './constants';

import { EC2LifecycleAction, ASGConfig } from './types';

const ssm = new SSMClient({ region });
const ec2 = new EC2Client({ region });
const ddb = new DynamoDBClient({ region });

const ddbDoc = DynamoDBDocumentClient.from(ddb);

async function sleep(waitTimeInMs: number) {
  return new Promise((resolve) => setTimeout(resolve, waitTimeInMs));
}

async function runCommand(
  docName: string,
  detail: EC2LifecycleAction
): Promise<SendCommandCommandOutput> {
  const input: SendCommandCommandInput = {
    DocumentName: docName,
    InstanceIds: [detail.EC2InstanceId],
    Parameters: {
      AutoScalingGroupName: [detail.AutoScalingGroupName],
      InstanceId: [detail.EC2InstanceId],
      LifecycleActionToken: [detail.LifecycleActionToken],
      LifecycleHookName: [detail.LifecycleHookName],
    },
  };

  const cmd: SendCommandCommand = new SendCommandCommand(input);
  const res: SendCommandCommandOutput = await ssm.send(cmd);

  return res;
}

async function instanceIsReady(instanceId: string): Promise<boolean> {
  const input: DescribeInstanceStatusCommandInput = {
    InstanceIds: [instanceId],
  };

  const cmd: DescribeInstanceStatusCommand = new DescribeInstanceStatusCommand(
    input
  );

  const res: DescribeInstanceStatusCommandOutput = await ec2.send(cmd);

  if (!res.InstanceStatuses || !res.InstanceStatuses.length) {
    return false;
  }

  const instanceStatus = res.InstanceStatuses[0].InstanceStatus.Status;
  const systemStatus = res.InstanceStatuses[0].SystemStatus.Status;

  return instanceStatus === 'ok' && systemStatus === 'ok';
}

async function ssmIsReady(instanceId: string): Promise<boolean> {
  const input: DescribeInstanceInformationCommandInput = {
    Filters: [
      {
        Key: 'InstanceIds',
        Values: [instanceId],
      },
    ],
  };

  const cmd: DescribeInstanceInformationCommand =
    new DescribeInstanceInformationCommand(input);

  const res: DescribeInstanceInformationCommandOutput = await ssm.send(cmd);

  if (!res.InstanceInformationList || !res.InstanceInformationList.length) {
    return false;
  }

  const pingStatus = res.InstanceInformationList[0].PingStatus;

  return pingStatus === 'Online';
}

async function getASGConfig(asgName: string): Promise<ASGConfig> {
  const input: GetCommandInput = {
    TableName: dbTableName,
    Key: {
      [dbHashKey]: asgName,
    },
  };

  const cmd: GetCommand = new GetCommand(input);

  const res = await ddbDoc
    .send(cmd)
    .then((res) => res.Item as ASGConfig)
    .catch((err) => {
      if (err instanceof ResourceNotFoundException) {
        throw new Error(
          `autoscaling group name <${asgName}> not found in DynamoDB table <${dbTableName}>`
        );
      }
      throw err;
    });

  return res;
}

function status(state: string, msg: string, time: number): string {
  return JSON.stringify(
    {
      status: state,
      msg,
      time,
    },
    null,
    2
  );
}

export { sleep, runCommand, instanceIsReady, ssmIsReady, getASGConfig, status };
