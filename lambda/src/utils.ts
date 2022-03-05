import {
  SSMClient,
  SendCommandCommandInput,
  SendCommandCommandOutput,
  SendCommandCommand,
} from '@aws-sdk/client-ssm';

import {
  EC2Client,
  DescribeInstanceStatusCommand,
  DescribeInstanceStatusCommandInput,
  DescribeInstanceStatusCommandOutput,
} from '@aws-sdk/client-ec2';

import { region, docMap } from './constants';

import { EC2LifecycleAction } from './types';

const ssm = new SSMClient({ region });
const ec2 = new EC2Client({ region });

async function runCommand(
  detail: EC2LifecycleAction
): Promise<SendCommandCommandOutput> {
  const input: SendCommandCommandInput = {
    DocumentName: docMap.get(detail.LifecycleTransition),
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

async function sleep(waitTimeInMs: number) {
  return new Promise((resolve) => setTimeout(resolve, waitTimeInMs));
}

export { runCommand, instanceIsReady, sleep };
