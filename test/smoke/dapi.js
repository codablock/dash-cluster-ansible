const DAPIClient = require('@dashevo/dapi-client');

const getNetworkConfig = require('../../lib/test/getNetworkConfig');

const { variables, inventory } = getNetworkConfig();

const evoMasternodes = inventory.hp_masternodes?.hosts ?? [];

describe('DAPI', () => {
  describe('Evo masternodes', () => {
    // Set up vars and functions to hold DAPI responses
    const bestBlockHash = {};
    const bestBlockHashError = {};
    const status = {};
    const statusError = {};
    const dataContract = {};
    const dataContractError = {};

    before('Collect blockhash, status and data contract info and errors', function func() {
      this.timeout(120000); // set mocha timeout

      if (variables.dashmate_platform_enable === false) {
        this.skip('platform is disabled for this network');
      }

      const promises = [];
      for (const hostName of evoMasternodes) {
        if (!inventory.meta.hostvars[hostName]) {
          // eslint-disable-next-line no-continue
          continue;
        }

        const timeout = 15000; // set individual dapi client timeout
        const unknownContractId = Buffer.alloc(32).fill(1);

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

        const requestBestBlockHash = dapiClient.core.getBestBlockHash()
          // eslint-disable-next-line no-loop-func
          .then((result) => {
            bestBlockHash[hostName] = result;
          })
          .catch((e) => {
            bestBlockHashError[hostName] = e;
          });

        const requestStatus = dapiClient.core.getStatus()
          // eslint-disable-next-line no-loop-func
          .then((result) => {
            status[hostName] = result;
          })
          .catch((e) => {
            statusError[hostName] = e;
          });

        const requestDataContract = dapiClient.platform.getDataContract(unknownContractId)
          // eslint-disable-next-line no-loop-func
          .then((result) => {
            dataContract[hostName] = result;
          })
          .catch((e) => {
            dataContractError[hostName] = e;
          });

        promises.push(requestBestBlockHash, requestStatus, requestDataContract);
      }

      return Promise.all(promises);
    });

    for (const hostName of evoMasternodes) {
      describe(hostName, () => {
        it('should return data from Core', async () => {
          if (bestBlockHashError[hostName]) {
            expect.fail(null, null, bestBlockHashError[hostName]);
          }

          if (!bestBlockHash[hostName]) {
            expect.fail('no block info');
          }

          expect(bestBlockHash[hostName]).to.be.a('string');
        });

        it('should return data from Core using gRPC', async () => {
          if (statusError[hostName]) {
            expect.fail(null, null, statusError[hostName]);
          }

          if (!status[hostName]) {
            expect.fail('no status info');
          }

          expect(status[hostName]).to.have.a.property('version');
          expect(status[hostName]).to.have.a.property('time');
          expect(status[hostName]).to.have.a.property('status');
          expect(status[hostName]).to.have.a.property('syncProgress');
          expect(status[hostName]).to.have.a.property('chain');
          expect(status[hostName]).to.have.a.property('masternode');
          expect(status[hostName]).to.have.a.property('network');
        });

        it('should return data from Platform', async () => {
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
