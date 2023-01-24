const createRpcClientFromConfig = require('../../lib/test/createRpcClientFromConfig');
const getNetworkConfig = require('../../lib/test/getNetworkConfig');
const { getDocker, execCommand, getContainerId } = require('../../lib/test/docker');

const { inventory, network, variables } = getNetworkConfig();

const allHosts = inventory.masternodes.hosts.concat(
  inventory.wallet_nodes.hosts,
  inventory.miners.hosts,
  inventory.seed_nodes.hosts,
);

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

describe('Quorums', () => {
  describe('All nodes', () => {
    // Set up vars to hold mn responses
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
      for (const hostName of allHosts) {
        if (inventory.masternodes.hosts.indexOf(hostName) !== -1) {
          const docker = getDocker(inventory.meta.hostvars[hostName].public_ip);

          const promise = getContainerId(docker, 'core')
            .then((containerId) => {
              containerIds[hostName] = containerId;

              return containerId;
            })
            .then((containerId) => Promise.all([
              execCommand(docker, containerId, ['dash-cli', 'getblockcount']),
              execCommand(docker, containerId, ['dash-cli', 'getbestchainlock']),
              execCommand(docker, containerId, ['dash-cli', 'getblockchaininfo']),
              execCommand(docker, containerId, ['dash-cli', 'quorum', 'list']),
            ])
              .then(([getBlockCount, getBestChainLock, getBlockchainInfo, quorumList]) => {
                blockCount[hostName] = getBlockCount;
                bestChainLock[hostName] = getBestChainLock;
                blockchainInfo[hostName] = getBlockchainInfo;
                quorumLists[hostName] = quorumList;
              }));

          promises.push(promise);
        } else {
          const timeout = 15000; // set individual rpc client timeout

          const client = createRpcClientFromConfig(hostName);

          client.setTimeout(timeout);

          const requestBlockCountPromise = client.getBlockCount()
            // eslint-disable-next-line no-loop-func
            .then(({ result }) => {
              blockCount[hostName] = result;
            });

          const requestBestChainLockPromise = client.getBestChainLock()
            .then(({ result }) => {
              bestChainLock[hostName] = result;
            });

          const requestQuorumListPromise = client.quorum('list')
            .then(({ result }) => {
              quorumLists[hostName] = result;
            });

          const requestBlockchainInfoPromise = client.getBlockchainInfo()
            .then(({ result }) => {
              blockchainInfo[hostName] = result;
            });

          promises.push(
            requestBlockCountPromise,
            requestBestChainLockPromise,
            requestQuorumListPromise,
            requestBlockchainInfoPromise,
          );
        }
      }

      return Promise.all(promises).catch(console.error);
    });

    before('Collect quorum info', () => {
      const promises = [];
      for (const hostName of allHosts) {
        if (quorumLists[hostName][quorumCheckTypes[network.type].name].length > 0) {
          if (inventory.masternodes.hosts.indexOf(hostName) !== -1) {
            const docker = getDocker(inventory.meta.hostvars[hostName].public_ip);

            const promise = execCommand(docker, containerIds[hostName],
              ['dash-cli', 'quorum', 'info',
                String(quorumCheckTypes[network.type].type),
                quorumLists[hostName][quorumCheckTypes[network.type].name][0]])
              .then((result) => {
                firstQuorumInfo[hostName] = result;
              });

            promises.push(promise);
          } else {
            const timeout = 15000; // set individual rpc client timeout

            const client = createRpcClientFromConfig(hostName);

            client.setTimeout(timeout);

            const requestFirstQuorumInfo = client.quorum(
              'info',
              quorumCheckTypes[network.type].type,
              quorumLists[hostName][quorumCheckTypes[network.type].name][0],
            )
              // eslint-disable-next-line no-loop-func
              .then(({ result }) => {
                firstQuorumInfo[hostName] = result;
              });

            promises.push(requestFirstQuorumInfo);
          }
        }
      }

      return Promise.all(promises).catch(console.error);
    });

    before('Send a transaction', () => {
      const promises = [];
      const timeout = 15000; // set individual rpc client timeout

      const client = createRpcClientFromConfig(inventory.wallet_nodes.hosts[0]);

      client.setTimeout(timeout);

      const requestGetBalance = client.sendToAddress(variables.faucet_address, 0.1, { wallet: 'dashd-wallet-1-faucet' })
        .then(({ result }) => {
          instantsendTestTxid = result;
        });

      promises.push(requestGetBalance);

      return Promise.all(promises).catch(console.error);
    });

    before('Collect instantsend info', async () => {
      // Wait two seconds here before checking for IS locks
      // TODO: implement this.slow() and await IS ZMQ message to mark test response speed yellow/red
      await new Promise((resolve) => setTimeout(resolve, 2000));

      const promises = [];
      for (const hostName of allHosts) {
        if (inventory.masternodes.hosts.indexOf(hostName) !== -1) {
          const docker = getDocker(inventory.meta.hostvars[hostName].public_ip);

          const promise = execCommand(docker, containerIds[hostName],
            ['dash-cli', 'getrawmempool', 'true'])
            .then((result) => {
              rawMemPool[hostName] = result;
            });

          promises.push(promise);
        } else {
          const timeout = 15000; // set individual rpc client timeout

          const client = createRpcClientFromConfig(hostName);

          client.setTimeout(timeout);

          const requestGetRawMemPool = client.getRawMemPool(true)
            // eslint-disable-next-line no-loop-func
            .then(({ result }) => {
              rawMemPool[hostName] = result;
            });

          promises.push(requestGetRawMemPool);
        }
      }

      return Promise.all(promises).catch(console.error);
    });

    for (const hostName of allHosts) {
      // eslint-disable-next-line no-loop-func
      describe(hostName, () => {
        it('should see quorums of the correct type', () => {
          expect(quorumLists[hostName][quorumCheckTypes[network.type].name]).to.not.be.empty();
        });

        it('should see chainlocks at the chain tip', () => {
          expect(blockCount[hostName]).to.equal(bestChainLock[hostName].height);
        });

        it('should see the first quorum was created recently', () => {
          expect(blockCount[hostName] - firstQuorumInfo[hostName].height)
            .to.be.lessThanOrEqual(quorumCheckTypes[network.type].dkgInterval * 1.5);
        });

        it('should see an instantsend lock', () => {
          expect(rawMemPool[hostName][instantsendTestTxid].instantlock).to.be.true();
        });
      });
    }
  });
});
