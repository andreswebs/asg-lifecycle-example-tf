import { Event } from './types';

import {
  sleep,
  runCommand,
  instanceIsReady,
  ssmIsReady,
  getASGConfig,
  status,
} from './utils';

import { transitionMap } from './constants';

const waitTimeInMs = 10000;

async function handler(event: Event) {
  const { detail } = event;
  console.log(JSON.stringify(detail, null, 2));

  const startTime: number = Date.now();
  let state = 'pending';
  let msg = `waiting to run command doc on instance ${detail.EC2InstanceId}`;

  try {
    const asgConfig = await getASGConfig(detail.AutoScalingGroupName);

    const docName = asgConfig[transitionMap.get(detail.LifecycleTransition)];

    console.log(status(state, msg, startTime));

    while (!(await instanceIsReady(detail.EC2InstanceId))) {
      await sleep(waitTimeInMs);
    }

    while (!(await ssmIsReady(detail.EC2InstanceId))) {
      await sleep(waitTimeInMs);
    }

    const now = Date.now();
    const elapsed = (now - startTime) / 1000;

    state = 'ready';
    msg = `time elapsed: ${elapsed}s; running command doc ${docName} on instance ${detail.EC2InstanceId}`;

    console.log(status(state, msg, now));

    const res = await runCommand(docName, detail);

    console.log(JSON.stringify(res, null, 2));
    return res;
  } catch (e) {
    console.error(e);
  }
}

export { handler };
