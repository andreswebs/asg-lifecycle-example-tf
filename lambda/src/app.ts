import { Event } from './types';

import { runCommand, instanceIsReady, sleep } from './utils';

const waitTimeInMs = 5000;

async function handler(event: Event) {
  const { detail } = event;
  console.log(JSON.stringify(detail, null, 2));

  try {
    while (!(await instanceIsReady(detail.EC2InstanceId))) {
      console.log(
        `instance not ready; waiting ${waitTimeInMs.toString()}ms before retry`
      );
      await sleep(waitTimeInMs);
    }

    const res = await runCommand(detail);

    console.log(JSON.stringify(res, null, 2));
    return res;
  } catch (e) {
    console.error(e);
  }
}

export { handler };
