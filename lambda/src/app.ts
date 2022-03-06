import { Event } from './types';

import { sleep, runCommand, instanceIsReady, getASGConfig } from './utils';

import { transitionMap } from './constants';

const waitTimeInMs = 5000;

async function handler(event: Event) {
  const { detail } = event;
  console.log(JSON.stringify(detail, null, 2));

  try {
    const asgConfig = await getASGConfig(detail.AutoScalingGroupName);

    const docName = asgConfig[transitionMap.get(detail.LifecycleTransition)];

    while (!(await instanceIsReady(detail.EC2InstanceId))) {
      console.log(
        `instance not ready; waiting ${waitTimeInMs.toString()}ms before retry`
      );
      await sleep(waitTimeInMs);
    }

    const res = await runCommand(docName, detail);

    console.log(JSON.stringify(res, null, 2));
    return res;
  } catch (e) {
    console.error(e);
  }
}

export { handler };
