const region =
  process.env.AWS_DEFAULT_REGION || process.env.AWS_REGION || 'us-east-1';

const transitionLaunch = 'autoscaling:EC2_INSTANCE_LAUNCHING' as const;
const transitionTerminate = 'autoscaling:EC2_INSTANCE_TERMINATING' as const;

const docLaunch = process.env.SSM_DOC_LAUNCH;
const docTerminate = process.env.SSM_DOC_TERMINATE;

if (!docLaunch) {
  throw new Error('missing env var: SSM_DOC_LAUNCH');
}
if (!docTerminate) {
  throw new Error('missing env var: SSM_DOC_TERMINATE');
}

const docMap = new Map<string, string>();
docMap.set(transitionLaunch, docLaunch);
docMap.set(transitionTerminate, docTerminate);

export { region, docMap };
