/* eslint-disable no-loop-func */
const DAPIClient = require('@dashevo/dapi-client');

const { Block } = require('@dashevo/dashcore-lib');

// eslint-disable-next-line no-undef
const { config: { testVariables: { inventory, variables } } } = __karma__;

describe('DAPI', () => {
  describe('All nodes', () => {
    const blockByHeight = {};
    const blockByHeightError = {};
    const blockByHash = {};
    const blockByHashError = {};
    const dataContract = {};
    const dataContractError = {};

    before('Collect block height info', async function collect() {
      if (variables.dashmate_platform_enable === false) {
        this.skip('platform is disabled for this network');
      }

      const promises = [];

      for (const hostName of inventory.hp_masternodes.hosts) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const timeout = 10000; // set individual dapi client timeout

        const dapiAddress = {
          protocol: 'https',
          host: inventory.meta.hostvars[hostName].public_ip,
          port: variables.gateway_port,
          allowSelfSignedCertificate: variables.dashmate_platform_gateway_ssl_provider !== 'zerossl',
        };

        const dapiClient = new DAPIClient({
          dapiAddresses: [dapiAddress],
          timeout,
        });

        const requestBlockByHeight = dapiClient.core.getBlockByHeight(1)
          .then((result) => {
            blockByHeight[hostName] = new Block(result);
          })
          .catch((e) => {
            blockByHeightError[hostName] = e;
          });
        promises.push(requestBlockByHeight);
      }

      return Promise.all(promises);
    });

    before('Collect block hash and contract info', async () => {
      const promises = [];

      for (const hostName of inventory.hp_masternodes.hosts) {
        if (!blockByHeight[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const timeout = 10000; // set individual dapi client timeout
        const unknownContractId = Buffer.alloc(32)
          .fill(1);

        const dapiAddress = {
          protocol: 'https',
          host: inventory.meta.hostvars[hostName].public_ip,
          port: variables.gateway_port,
          allowSelfSignedCertificate: variables.dashmate_platform_gateway_ssl_provider !== 'zerossl',
        };

        const dapiClient = new DAPIClient({
          dapiAddresses: [dapiAddress],
          timeout,
        });

        // eslint-disable-next-line max-len
        const requestBlockByHash = dapiClient.core.getBlockByHash(blockByHeight[hostName].header.hash)
          .then((result) => {
            blockByHash[hostName] = new Block(result);
          })
          .catch((e) => {
            blockByHashError[hostName] = e;
          });

        const requestDataContract = dapiClient.platform.getDataContract(unknownContractId)
          .then((result) => {
            dataContract[hostName] = result;
          })
          .catch((e) => {
            dataContractError[hostName] = e;
          });

        promises.push(requestBlockByHash, requestDataContract);
      }

      await Promise.all(promises).catch(() => Promise.resolve());
    });

    for (const hostName of inventory.hp_masternodes.hosts) {
      describe(hostName, () => {
        it('should respond with Core data via gRPC Web', () => {
          if (blockByHeightError[hostName]) {
            expect.fail(null, null, blockByHeightError[hostName]);
          }

          if (!blockByHash[hostName]) {
            expect.fail('no response');
          }

          expect(blockByHeight[hostName].toJSON()).to.deep.equal(blockByHash[hostName].toJSON());
        });

        it('should respond with Platform data via gRPC Web', () => {
          if (!dataContractError[hostName]) {
            expect.fail(null, null, 'no dapi error info');
          }

          expect(dataContract[hostName]).to.be.undefined();
          expect(dataContractError[hostName].code).to.be.equal(5);
        });
      });
    }
  });
});
