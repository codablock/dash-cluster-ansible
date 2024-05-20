const wait = require('@dashevo/dapi-client/lib/utils/wait');
const createRpcClientFromConfig = require('../../lib/test/createRpcClientFromConfig');
const getNetworkConfig = require('../../lib/test/getNetworkConfig');
const { createDocker, execJSONDockerCommand, getContainerId } = require('../../lib/test/docker');

const { inventory, network, variables } = getNetworkConfig();

const allHosts = inventory.masternodes.hosts.concat(
  inventory.hp_masternodes.hosts,
  inventory.wallet_nodes.hosts,
  inventory.miners.hosts,
  inventory.seed_nodes.hosts,
);

const ansibleHosts = inventory.masternodes.hosts.concat(
  inventory.wallet_nodes.hosts,
  inventory.miners.hosts,
  inventory.seed_nodes.hosts,
);
const dashmateHosts = inventory.hp_masternodes.hosts;

const quorumCheckTypes = {
  testnet: {
    name: 'llmq_100_67',
    type: 4,
    dkgInterval: 24,
  },
  mainnet: {
    name: 'llmq_400_60',
    type: 2,
    dkgInterval: 288,
  },
  devnet: {
    name: 'llmq_devnet',
    type: 101,
    dkgInterval: 24,
  },
  regtest: {
    name: 'llmq_test',
    type: 100,
    dkgInterval: 24,
  },
};

function rejectAfterTimeout(promise, timeout) {
  const rejectPromise = new Promise((resolve, reject) => {
    setTimeout(() => {
      reject(new Error(`Timeout of ${timeout}ms exceeded`));
    }, timeout);
  });

  return Promise.race([promise, rejectPromise]);
}

describe('Quorums', () => {
  describe('All nodes', () => {
    // Set up vars to hold mn responses
    const errors = {};
    const blockCount = {};
    const bestChainLock = {};
    const quorumLists = {};
    const blockchainInfo = {};
    const firstQuorumInfo = {};
    const rawMemPool = {};
    const containerIds = {};
    let instantsendTestTxid = '';

    before('Collect chain lock and quorum list', async () => {
      // this.timeout(60000); // set mocha timeout

      const promises = [];

      for (const hostName of ansibleHosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const timeout = 15000; // set individual rpc client timeout

        const client = createRpcClientFromConfig(hostName);

        client.setTimeout(timeout);

        const requestBlockCountPromise = client.getBlockCount()
          // eslint-disable-next-line no-loop-func
          .then(({ result }) => {
            blockCount[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        const requestBestChainLockPromise = client.getBestChainLock()
          .then(({ result }) => {
            bestChainLock[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        const requestQuorumListPromise = client.quorum('list')
          .then(({ result }) => {
            quorumLists[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        const requestBlockchainInfoPromise = client.getBlockchainInfo()
          .then(({ result }) => {
            blockchainInfo[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        promises.push(
          requestBlockCountPromise,
          requestBestChainLockPromise,
          requestQuorumListPromise,
          requestBlockchainInfoPromise,
        );
      }

      for (const hostName of dashmateHosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const docker = createDocker(inventory.meta.hostvars[hostName].public_ip, {
          timeout: 15000,
        });

        const commandPromise = getContainerId(docker, 'core')
          .then((containerId) => {
            containerIds[hostName] = containerId;

            return containerId;
          })
          .then((containerId) => Promise.all([
            execJSONDockerCommand(docker, containerId, ['dash-cli', 'getblockcount']),
            execJSONDockerCommand(docker, containerId, ['dash-cli', 'getbestchainlock']),
            execJSONDockerCommand(docker, containerId, ['dash-cli', 'getblockchaininfo']),
            execJSONDockerCommand(docker, containerId, ['dash-cli', 'quorum', 'list']),
          ]).then(([getBlockCount, getBestChainLock, getBlockchainInfo, quorumList]) => {
            blockCount[hostName] = getBlockCount;
            bestChainLock[hostName] = getBestChainLock;
            blockchainInfo[hostName] = getBlockchainInfo;
            quorumLists[hostName] = quorumList;
          }));

        const promise = rejectAfterTimeout(commandPromise, 15000)
          .catch((error) => {
            errors[hostName] = error;
          });

        promises.push(promise);
      }

      return Promise.all(promises);
    });

    before('Collect quorum info', () => {
      const promises = [];

      const timeout = 15000; // set individual rpc client timeout

      for (const hostName of ansibleHosts) {
        if (!quorumLists[hostName]
          || quorumLists[hostName][quorumCheckTypes[network.type].name].length === 0) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const client = createRpcClientFromConfig(hostName);

        client.setTimeout(timeout);

        const requestFirstQuorumInfo = client.quorum(
          'info',
          quorumCheckTypes[network.type].type,
          quorumLists[hostName][quorumCheckTypes[network.type].name][0],
        );

        const promise = rejectAfterTimeout(requestFirstQuorumInfo, timeout)
          // eslint-disable-next-line no-loop-func
          .then(({ result }) => {
            firstQuorumInfo[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        promises.push(promise);
      }

      for (const hostName of dashmateHosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        if (!quorumLists[hostName]
          || quorumLists[hostName][quorumCheckTypes[network.type].name].length === 0) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const docker = createDocker(inventory.meta.hostvars[hostName].public_ip, {
          timeout,
        });

        const commandPromise = execJSONDockerCommand(
          docker,
          containerIds[hostName],
          [
            'dash-cli',
            'quorum',
            'info',
            String(quorumCheckTypes[network.type].type),
            quorumLists[hostName][quorumCheckTypes[network.type].name][0],
          ],
        );

        const promise = rejectAfterTimeout(commandPromise, timeout)
          .then((result) => {
            firstQuorumInfo[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        promises.push(promise);
      }

      return Promise.all(promises);
    });

    before('Send a transaction', async function before() {
      const timeout = 60000; // set individual rpc client timeout
      this.timeout(timeout); // set mocha timeout

      const client = createRpcClientFromConfig(inventory.wallet_nodes.hosts[0]);

      client.setTimeout(timeout);

      ({ result: instantsendTestTxid } = await client.sendToAddress(variables.faucet_address, 0.1, { wallet: 'dashd-wallet-1-faucet' }));
    });

    before('Collect instantsend info', async function before() {
      this.timeout(30000); // set mocha timeout

      // Wait six seconds here before checking for IS locks
      // TODO: implement this.slow() and await IS ZMQ message to mark test response speed yellow/red
      await wait(6000);

      const promises = [];

      const timeout = 15000; // set individual rpc client timeout

      for (const hostName of ansibleHosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const client = createRpcClientFromConfig(hostName);

        client.setTimeout(timeout);

        const requestGetRawMemPool = client.getRawMemPool(true);

        const promise = rejectAfterTimeout(requestGetRawMemPool, timeout)
          .then(({ result }) => {
            rawMemPool[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        promises.push(promise);
      }

      for (const hostName of dashmateHosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const docker = createDocker(inventory.meta.hostvars[hostName].public_ip, {
          timeout,
        });

        const commandPromise = execJSONDockerCommand(
          docker,
          containerIds[hostName],
          ['dash-cli', 'getrawmempool', 'true'],
        );

        const promise = rejectAfterTimeout(commandPromise, timeout)
          .then((result) => {
            rawMemPool[hostName] = result;
          }).catch((error) => {
            errors[hostName] = error;
          });

        promises.push(promise);
      }

      return Promise.all(promises);
    });

    for (const hostName of allHosts) {
      // eslint-disable-next-line no-loop-func
      describe(hostName, () => {
        it('should see quorums of the correct type', () => {
          if (errors[hostName]) {
            expect.fail(errors[hostName]);
          }

          expect(quorumLists).to.have.property(hostName);

          expect(quorumLists[hostName][quorumCheckTypes[network.type].name]).to.not.be.empty();
        });

        it('should see chainlocks at the chain tip', () => {
          if (errors[hostName]) {
            expect.fail(errors[hostName]);
          }

          expect(bestChainLock).to.have.property(hostName);

          expect(blockCount[hostName]).to.equal(bestChainLock[hostName].height);
        });

        it('should see the first quorum was created recently', () => {
          if (errors[hostName]) {
            expect.fail(errors[hostName]);
          }

          expect(firstQuorumInfo).to.have.property(hostName);
          expect(blockCount).to.have.property(hostName);

          expect(blockCount[hostName] - firstQuorumInfo[hostName].height)
            .to.be.lessThanOrEqual(quorumCheckTypes[network.type].dkgInterval * 1.5);
        });

        it('should see an instantsend lock', () => {
          if (errors[hostName]) {
            expect.fail(errors[hostName]);
          }

          expect(rawMemPool).to.have.property(hostName);
          expect(rawMemPool[hostName]).to.have.property(instantsendTestTxid);
          expect(rawMemPool[hostName][instantsendTestTxid].instantlock).to.equal('true');
        });
      });
    }
  });
});
