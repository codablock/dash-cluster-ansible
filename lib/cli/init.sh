# Validate network name

NETWORK_NAME=$1
networks=("regtest" "testnet" "devnet" "mainnet" "mainnet-support")

print_error() {
    echo "$1" >&2
    exit 1
}

if grep -q "devnet-" <<< "$NETWORK_NAME"; then
    NETWORK="devnet"
    NETWORK_DEVNET_NAME="${NETWORK_NAME:7}"
    if [ -z $NETWORK_DEVNET_NAME ]; then
        print_error "Invalid devnet network name format. Required format is 'devnet-<name>'"
    fi
elif [[ " ${networks[@]} " =~ " ${NETWORK_NAME} " ]]; then
    NETWORK="$NETWORK_NAME"
else
    print_error "Invalid network name '$NETWORK_NAME'. Supported networks: regtest, devnet-<name>, testnet, mainnet"
fi

INVENTORY_FILE="networks/$NETWORK_NAME.inventory"
ANSIBLE_CONFIG_PATH="networks/$NETWORK_NAME.yml"
TERRAFORM_CONFIG_PATH="networks/$NETWORK_NAME.tfvars"
VPN_CONFIG_PATH="networks/$NETWORK_NAME.ovpn"

# Load configuration

if [ ! -f networks/.env ]; then

    echo "Configuration .env file not found.

Generating blank '.env' file... "

  mkdir -p networks
  cat > networks/.env<< EOF
# Terraform remote backend configuration https://www.terraform.io/docs/backends/types/s3.html
TERRAFORM_S3_BUCKET=""
TERRAFORM_S3_KEY=""
TERRAFORM_DYNAMODB_TABLE=""
# Absolute paths to private and public keys for SSH access to an infrastructure
PRIVATE_KEY_PATH=""
PUBLIC_KEY_PATH=""
# AWS credentials are used by Terraform for creating infrastructure
#
# You should specify credentials for both
# Ansible and Terraform or specify a particular
# configuration using "TERRAFORM_" and "ANSIBLE_" prefixes
# AWS_PROFILE="" # You can use AWS_PROFILE instead of AWS credentials
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION=""
# TERRAFORM_AWS_PROFILE=""
# TERRAFORM_AWS_ACCESS_KEY_ID=""
# TERRAFORM_AWS_SECRET_ACCESS_KEY=""
# TERRAFORM_AWS_REGION=""
# ANSIBLE_AWS_PROFILE=""
# ANSIBLE_AWS_ACCESS_KEY_ID=""
# ANSIBLE_AWS_SECRET_ACCESS_KEY=""
# ANSIBLE_AWS_REGION=""
EOF

fi

if [ -f networks/.env ]; then
    source networks/.env
fi
