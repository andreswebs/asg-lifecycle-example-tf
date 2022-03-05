import { EventBridgeEvent } from 'aws-lambda';

interface EC2LifecycleAction {
  LifecycleHookName: string;
  LifecycleTransition: string;
  AutoScalingGroupName: string;
  EC2InstanceId: string;
  LifecycleActionToken: string;
  NotificationMetadata: string;
  Origin: string;
  Destination: string;
}

type LaunchDetailType = 'EC2 Instance-launch Lifecycle Action';
type TerminateDetailType = 'EC2 Instance-terminate Lifecycle Action';

type Event =
  | EventBridgeEvent<LaunchDetailType, EC2LifecycleAction>
  | EventBridgeEvent<TerminateDetailType, EC2LifecycleAction>;

export type { Event, EC2LifecycleAction };
