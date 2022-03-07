const region =
  process.env.AWS_DEFAULT_REGION || process.env.AWS_REGION || 'us-east-1';

const transitionLaunch = 'autoscaling:EC2_INSTANCE_LAUNCHING' as const;
const transitionTerminate = 'autoscaling:EC2_INSTANCE_TERMINATING' as const;

const transitionMap = new Map<string, string>();
transitionMap.set(transitionLaunch, 'Launch');
transitionMap.set(transitionTerminate, 'Terminate');

const dbHashKey = process.env.DB_HASH_KEY || 'AutoscalingGroupName';
const dbTableName = process.env.DB_TABLE_NAME;

if (!dbTableName) {
  throw new Error('missing env var: DB_TABLE_NAME');
}

export { region, dbTableName, dbHashKey, transitionMap };
