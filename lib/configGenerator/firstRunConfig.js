const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');
const { PrivateKey } = require('@dashevo/dashcore-lib');

async function generateDashAddress(network) {
  const privateKey = new PrivateKey(undefined, network);

  return {
    address: privateKey.toAddress(network).toString(),
    private_key: privateKey.toWIF(),
  };
}

function parseTfvarsToJSON(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split(/\r?\n/);
  const result = {};

  lines.forEach((line) => {
    // Ignore empty lines and comments
    if (!line || line.trim().startsWith('#')) {
      return;
    }

    // Split line by '=', trimming whitespace and handling quotes
    const [key, value] = line.split('=').map((part) => part.trim().replace(/^"(.*)"$/, '$1'));

    // Convert to appropriate data type and add to result object
    result[key] = Number.isNaN(Number(value)) ? value : Number(value);
  });

  return result;
}

async function firstRunConfig(
  network,
  networkName,
) {
  // Load files
  const tfvarsFilePath = path.join('networks/', `${networkName}.tfvars`);
  const ymlFilePath = path.join('networks/', `${networkName}.yml`);
  const yamlFile = fs.readFileSync(ymlFilePath, 'utf8');

  let ansibleYml;
  // Added error handling for YAML parsing to prevent application crashes on malformed YAML files
  try {
    ansibleYml = yaml.load(yamlFile);
  } catch (error) {
    console.error('Failed to parse YAML:', error); // Error logging on YAML parse failure
    return; // Return early to avoid further execution with invalid data
  }

  const tfjson = parseTfvarsToJSON(tfvarsFilePath);

  // Count the mixers, dynamically add/remove if needed
  const mixerCountJson = tfjson.mixer_count;
  let mixerCountYml = Object.keys(ansibleYml.mixers).length;

  // Count the load testing nodes...
  const LTCountJson = tfjson.load_test_count;
  let LTCountYml = Object.keys(ansibleYml.load_testers).length;

  const mixYml = Object(ansibleYml.mixers);
  const LTYml = Object(ansibleYml.load_testers);

  // Ensure we have the right amount of mixers in the yml
  while (mixerCountJson > mixerCountYml) {
    const nextMixerNumber = mixerCountYml + 1;
    const mixerKey = `mixer-${nextMixerNumber}`;
    mixYml[mixerKey] = { owner: await generateDashAddress(network) };
    mixerCountYml = Object.keys(mixYml).length;
  }

  while (mixerCountYml > mixerCountJson) {
    const lastMixerNumber = mixerCountYml;
    const mixerKey = `mixer-${lastMixerNumber}`;

    // Delete the extra entry from the mixYml object
    delete mixYml[mixerKey];

    // Update the mixerCountYml to reflect the deletion
    mixerCountYml = Object.keys(mixYml).length;
  }

  // And the load testers...
  while (LTCountJson > LTCountYml) {
    const nextLTNumber = LTCountYml + 1;
    const LTKey = `load-tester-${nextLTNumber}`;
    LTYml[LTKey] = { owner: await generateDashAddress(network) };
    LTCountYml = Object.keys(LTYml).length;
  }

  // Delete extra load testers if LTCountJson is less than LTCountYml
  while (LTCountYml > LTCountJson) {
    const lastLTNumber = LTCountYml;
    const LTKey = `load-tester-${lastLTNumber}`;
    delete LTYml[LTKey];
    LTCountYml = Object.keys(LTYml).length;
  }

  ansibleYml.mixers = mixYml;
  ansibleYml.load_testers = LTYml;

  // Write the new file...
  const newYaml = yaml.dump(ansibleYml);
  fs.writeFile(ymlFilePath, newYaml, 'utf8', (err) => {
    if (err) {
      console.error('Error writing file:', err); // Changed logging level to error to highlight write failures
    } else {
      console.log('Successfully wrote updated YAML to', ymlFilePath);
    }
  });
}

module.exports = firstRunConfig;