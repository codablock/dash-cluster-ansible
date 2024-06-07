const fs = require('fs').promises;

const { PrivateKey } = require('@dashevo/dashcore-lib');
const { Wallet } = require('@dashevo/wallet-lib');

const BlsSignatures = require('@dashevo/bls');

const yaml = require('js-yaml');

const crypto = require('crypto');

/**
 * Get identity HDPrivateKey for network
 *
 * @typedef {generateHDPrivateKeys}
 *
 * @param {string} network
 *
 * @returns {Promise<HDPrivateKey>}
 */
async function generateHDPrivateKeys(network) {
  const wallet = new Wallet({ network, offlineMode: true });
  const account = await wallet.getAccount();

  const derivedMasterPrivateKey = account.identities.getIdentityHDKeyByIndex(0, 0);
  const derivedSecondPrivateKey = account.identities.getIdentityHDKeyByIndex(0, 1);
  const hdPrivateKey = wallet.exportWallet('HDPrivateKey');

  await wallet.disconnect();

  return {
    hdPrivateKey,
    derivedMasterPrivateKey,
    derivedSecondPrivateKey,
  };
}

async function generateAnsibleConfig(
  network,
  networkName,
  masternodesCount,
  hpMasternodesCount,
  seedsCount,
) {
  const config = {};

  // Set vars here!!
  config.evo_services = true;
  config.drive_image = 'dashpay/drive:latest-dev';
  config.dapi_image = 'dashpay/dapi:latest-dev';
  config.gateway_image = 'dashpay/envoy:latest';
  config.dashd_image = 'dashpay/dashd:latest-dev';
  config.tendermint_image = 'dashpay/tenderdash:latest';
  config.insight_api_image = 'dashpay/insight-api:latest';
  config.insight_image = 'dashpay/insight:latest';
  config.multifaucet_image = 'dashpay/multifaucet:latest';
  config.dashmate_version = '0.25.0-dev.28';
  config.main_domain = '';
  config.tenderdash_chain_id = networkName;

  const {
    hdPrivateKey: dpnsHDPrivateKey,
    derivedMasterPrivateKey: dpnsDerivedMasterPK,
    derivedSecondPrivateKey: dpnsDerivedSecondPK,
  } = await generateHDPrivateKeys(network);
  const {
    hdPrivateKey: dashpayHDPrivateKey,
    derivedMasterPrivateKey: dashpayDerivedMasterPK,
    derivedSecondPrivateKey: dashpayDerivedSecondPK,
  } = await generateHDPrivateKeys(network);
  const {
    hdPrivateKey: featureFlagsHDPrivateKey,
    derivedMasterPrivateKey: featureFlagsDerivedMasterPK,
    derivedSecondPrivateKey: featureFlagsDerivedSecondPK,
  } = await generateHDPrivateKeys(network);
  const {
    hdPrivateKey: mnRewardSharesHDPrivateKey,
    derivedMasterPrivateKey: mnRewardSharesDerivedMasterPK,
    derivedSecondPrivateKey: mnRewardSharesDerivedSecondPK,
  } = await generateHDPrivateKeys(network);
  const {
    hdPrivateKey: withdrawalsHDPrivateKey,
    derivedMasterPrivateKey: withdrawalsDerivedMasterPK,
    derivedSecondPrivateKey: withdrawalsDerivedSecondPK,
  } = await generateHDPrivateKeys(network);

  const llmqParams = {
    devnet: {
      validatorSet: {
        llmqType: 107, // llmq_devnet_platform
        dkgInterval: 24,
        activeSigners: 4,
        rotation: false,
      },
      chainLock: {
        llmqType: 101, // llmq_devnet
        dkgInterval: 24,
        activeSigners: 4,
        rotation: false,
      },
      instantLock: {
        llmqType: 105, // llmq_devnet_dip0024
        dkgInterval: 48,
        activeSigners: 2,
        rotation: true,
      },
    },
    testnet: {
      validatorSet: {
        llmqType: 6,
        dkgInterval: 24,
        activeSigners: 24,
        rotation: false,
      },
      chainLock: {
        llmqType: 1,
        dkgInterval: 24,
        activeSigners: 24,
        rotation: false,
      },
      instantLock: {
        llmqType: 5,
        dkgInterval: 288,
        activeSigners: 32,
        rotation: true,
      },
    },
    mainnet: {
      validatorSet: {
        llmqType: 4,
        dkgInterval: 24,
        activeSigners: 24,
        rotation: false,
      },
      chainLock: {
        llmqType: 2,
        dkgInterval: 288,
        activeSigners: 4,
        rotation: false,
      },
      instantLock: {
        llmqType: 5,
        dkgInterval: 288,
        activeSigners: 32,
        rotation: true,
      },
    },
    regtest: {
      validatorSet: {
        llmqType: 106,
        dkgInterval: 24,
        activeSigners: 2,
        rotation: false,
      },
      chainLock: {
        llmqType: 100,
        dkgInterval: 24,
        activeSigners: 2,
        rotation: false,
      },
      instantLock: {
        llmqType: 104,
        dkgInterval: 24,
        activeSigners: 2,
        rotation: false,
      },
    },
  };

  config.platform_drive_validator_set_quorum_llmq_type = llmqParams[network].validatorSet.llmqType;
  config.platform_drive_validator_set_quorum_dkg_interval = llmqParams[network].validatorSet
    .dkgInterval;
  config.platform_drive_validator_set_quorum_active_signers = llmqParams[network].validatorSet
    .activeSigners;
  config.platform_drive_validator_set_quorum_rotation = llmqParams[network].validatorSet.rotation;
  config.platform_drive_chain_lock_quorum_llmq_type = llmqParams[network].chainLock.llmqType;
  config.platform_drive_chain_lock_quorum_dkg_interval = llmqParams[network].chainLock.dkgInterval;
  config.platform_drive_chain_lock_quorum_active_signers = llmqParams[network].chainLock
    .activeSigners;
  config.platform_drive_chain_lock_quorum_rotation = llmqParams[network].chainLock.rotation;
  config.platform_drive_instant_lock_quorum_llmq_type = llmqParams[network].instantLock.llmqType;
  config.platform_drive_instant_lock_quorum_dkg_interval = llmqParams[network].instantLock
    .dkgInterval;
  config.platform_drive_instant_lock_quorum_active_signers = llmqParams[network].instantLock
    .activeSigners;
  config.platform_drive_instant_lock_quorum_rotation = llmqParams[network].instantLock.rotation;

  config.platform_drive_abci_epoch_time = 788400;

  if (network === 'devnet') {
    // eslint-disable-next-line no-param-reassign
    network = 'testnet';
  }

  // Faucet
  const faucetPrivateKey = new PrivateKey(undefined, network);

  config.faucet_address = faucetPrivateKey.toAddress(network).toString();
  config.faucet_privkey = faucetPrivateKey.toWIF();

  // Spork
  const sporkPrivateKey = new PrivateKey(undefined, network);

  config.dashd_sporkaddr = sporkPrivateKey.toAddress(network).toString();
  config.dashd_sporkkey = sporkPrivateKey.toWIF();

  // Elastic keys
  config.elastic_password = crypto.randomBytes(32).toString('base64').slice(0, 32);
  config.kibana_password = crypto.randomBytes(32).toString('base64').slice(0, 32);
  config.kibana_encryptionkey = crypto.randomBytes(32).toString('base64').slice(0, 32);

  // Governance proposals
  config.governance_proposal_count = 2;

  // Mixer variables
  config.mix_amount = 100;
  config.remix_amount = 30;
  config.coinjoin_wallet_name = 'coinjoin-wallet';

  // HD private keys
  config.dpns_hd_private_key = dpnsHDPrivateKey.toString();
  config.dpns_hd_master_public_key = dpnsDerivedMasterPK.privateKey.toPublicKey().toString();
  config.dpns_hd_second_public_key = dpnsDerivedSecondPK.privateKey.toPublicKey().toString();

  config.dashpay_hd_private_key = dashpayHDPrivateKey.toString();
  config.dashpay_hd_master_public_key = dashpayDerivedMasterPK.privateKey.toPublicKey().toString();
  config.dashpay_hd_second_public_key = dashpayDerivedSecondPK.privateKey.toPublicKey().toString();

  config.feature_flags_hd_private_key = featureFlagsHDPrivateKey
    .toString();
  config.feature_flags_hd_master_public_key = featureFlagsDerivedMasterPK
    .privateKey.toPublicKey().toString();
  config.feature_flags_hd_second_public_key = featureFlagsDerivedSecondPK
    .privateKey.toPublicKey().toString();

  config.mn_reward_shares_hd_private_key = mnRewardSharesHDPrivateKey
    .toString();
  config.mn_reward_shares_hd_master_public_key = mnRewardSharesDerivedMasterPK
    .privateKey.toPublicKey().toString();
  config.mn_reward_shares_hd_second_public_key = mnRewardSharesDerivedSecondPK
    .privateKey.toPublicKey().toString();

  config.withdrawals_hd_private_key = withdrawalsHDPrivateKey
    .toString();
  config.withdrawals_hd_master_public_key = withdrawalsDerivedMasterPK
    .privateKey.toPublicKey().toString();
  config.withdrawals_hd_second_public_key = withdrawalsDerivedSecondPK
    .privateKey.toPublicKey().toString();

  // Dashd
  config.dashd_debug = 0;
  config.dashd_network_logging = 0;
  config.dashd_minimumdifficultyblocks = 4032;

  config.drive_log_stdout_level = 'debug';
  config.drive_log_json_file_level = 'debug';
  config.drive_log_pretty_file_level = 'debug';
  config.tenderdash_log_level = 'debug';

  // Genesis date
  config.genesis_time = new Date().toISOString();

  config.platform_initial_core_chain_locked_height = 4100;

  config.smoke_test_st_execution_interval = 15000;

  async function generateDashAddress() {
    const privateKey = new PrivateKey(undefined, network);

    return {
      address: privateKey.toAddress(network).toString(),
      private_key: privateKey.toWIF(),
    };
  }

  // Generate owner, collateral and operator keys
  const blsSignatures = await BlsSignatures();

  async function generateDip3Keys() {
    const owner = await generateDashAddress(network);
    const collateral = await generateDashAddress(network);

    const { BasicSchemeMPL } = blsSignatures;

    const randomBytes = new Uint8Array(crypto.randomBytes(256));
    const operatorPrivateKey = BasicSchemeMPL.keyGen(randomBytes);
    const operatorPublicKey = BasicSchemeMPL.skToG1(operatorPrivateKey);

    return {
      owner,
      collateral,
      operator: {
        public_key: Buffer.from(operatorPublicKey.serialize()).toString('hex'),
        private_key: Buffer.from(operatorPrivateKey.serialize()).toString('hex'),
      },
    };
  }

  // Masternode keys
  config.masternodes = {};

  for (let i = 1; i <= masternodesCount; i++) {
    config.masternodes[`masternode-${i}`] = await generateDip3Keys(network);
  }

  // HP masternode keys
  config.hp_masternodes = {};

  for (let i = 1; i <= hpMasternodesCount; i++) {
    config.hp_masternodes[`hp-masternode-${i}`] = await generateDip3Keys(network);
  }
  // Tenderdash keys

  function generateTenderdashNodeKeys() {
    const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519', {
      privateKeyEncoding: { format: 'der', type: 'pkcs8' },
      publicKeyEncoding: { format: 'der', type: 'spki' },
    });

    // Strip static metadata from keys so they are 32 bytes and
    // concatenate to 64 byte Tenderdash cached key
    const cachedKey = Buffer.concat([privateKey.slice(16), publicKey.slice(12)]);

    // Derive ID from key
    const publicKeyHash = crypto.createHash('sha256')
      .update(publicKey.slice(12))
      .digest('hex');

    const id = publicKeyHash.slice(0, 40);
    // eslint-disable-next-line camelcase
    const private_key = cachedKey.toString('base64');

    // eslint-disable-next-line camelcase
    return { id, private_key };
  }

  config.seed_nodes = {};

  for (let i = 1; i <= hpMasternodesCount; i++) {
    config.hp_masternodes[`hp-masternode-${i}`].node_key = generateTenderdashNodeKeys();
  }

  for (let i = 1; i <= seedsCount; i++) {
    config.seed_nodes[`seed-${i}`] = {};
    config.seed_nodes[`seed-${i}`].node_key = generateTenderdashNodeKeys();
  }

  const data = yaml.dump(config);

  await fs.writeFile(`networks/${networkName}.yml`, `---\n\n${data}`);
}

module.exports = generateAnsibleConfig;
