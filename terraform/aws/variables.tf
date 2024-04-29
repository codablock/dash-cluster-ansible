variable "public_key_path" {
}

variable "dashd_port" {
  description = "Port for Dash Core nodes"
  default     = 20001
}

variable "dashd_rpc_port" {
  description = "Port for Dash RPC interface"
  default     = 20002
}

variable "dashd_zmq_port" {
  description = "Port for Dash Zmq interface"
  default     = 29998
}

variable "faucet_port" {
  description = "Faucet port"
  default     = 80
}

variable "faucet_https_port" {
  description = "Faucet HTTPS port"
  default     = 443
}

variable "insight_port" {
  description = "Insight port"
  default     = 3001
}

variable "insight_https_port" {
  description = "Insight HTTPS port"
  default     = 3002
}

variable "ssh_port" {
  description = "SSH port"
  default     = 22
}

variable "drive_port" {
  description = "Drive port"
  default     = 6000
}

variable "dapi_port" {
  description = "DAPI port"
  default     = 1443
}

variable "tendermint_p2p_port" {
  description = "Tendermint P2P port"
  default     = 36656
}

variable "prometheus_port" {
  description = "Prometheus port"
  default     = 80
}

variable "tendermint_rpc_port" {
  description = "Tendermint RPC port"
  default     = 36657
}

variable "tendermint_abci_port" {
  description = "Tendermint ABCI port"
  default     = 26658
}

variable "docker_port" {
  description = "Docker API port"
  default     = 2375
}

variable "vpn_port" {
  description = "VPN port"
  default     = 1194
}

variable "kibana_port" {
  description = "Kibana port"
  default     = 5601
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "subnet_public_cidr" {
  type = list(any)
  default = [
    "10.0.16.0/20",
    "10.0.32.0/20",
    "10.0.48.0/20",
  ]
}

variable "seed_count" {
  default = 1
}

variable "miner_count" {
  default = 1
}

variable "mixer_count" {
  default = 0
}

variable "masternode_amd_count" {
  default = 3
}

variable "masternode_arm_count" {
  default = 3
}

variable "hp_masternode_amd_count" {
  default = 3
}

variable "hp_masternode_arm_count" {
  default = 3
}

# TODO: add support for multiple wallets/mnos
variable "wallet_count" {
  description = "number of wallet nodes to create. must be at least 1"
  default     = 1
}

variable "web_count" {
  default = 1
}

variable "logs_count" {
  default     = 1
  description = "number of logging nodes to create. set to 0 to disable logging for the network"
}

variable "load_test_count" {
  default     = 0
  description = "number of load testing nodes to create. set to 0 to disable load testing for the network"
}

variable "metrics_count" {
  default     = 0
  description = "number of metrics nodes to create. set to 0 to disable. Should generally not be higher than 1"
}

variable "main_host_arch" {
  description = "use amd64 (t3.*) or arm64 (t4g.*) EC2 instances for non-masternodes"
  default     = "arm64"
}

variable "vpn_enabled" {
  default     = true
  description = "setup instance for vpn"
}

variable "main_domain" {
  description = "domain name will be used for base for technical records"
  default     = ""
}

variable "monitoring_sns_arn" {
  description = "ARN of SNS topic that will receive notifications from monitoring"
  default     = ""
}

variable "public_network_name" {
  description = "Name of the network that will be used to create dns records"
  default     = ""
}

variable "monitoring_cpu_enabled" {
  description = "enable CPU utilization alarm with CloudWatch"
  default     = false
}

variable "monitoring_mem_enabled" {
  description = "enable memory used alarm with CloudWatch"
  default     = false
}

variable "monitoring_swap_enabled" {
  description = "enable swap used alarm with CloudWatch"
  default     = false
}

variable "monitoring_disk_enabled" {
  description = "enable disk used alarm with CloudWatch"
  default     = false
}

variable "core_node_disk_size" {
  description = "Default disk size for nodes, increase for testnet"
  default     = 20
}

variable "mn_node_disk_size" {
  description = "Disk size of masternodes"
  default     = 20
}

variable "hpmn_node_disk_size" {
  description = "Disk size of HP masternodes"
  default     = 30
}

variable "logs_node_root_disk_size" {
  description = "Default disk size for nodes, increase for testnet"
  default     = 20
}

variable "logs_node_instance_type" {
  description = "Instance type of log nodes"
  default     = "i4g"
}

variable "logs_node_instance_size" {
  description = "Instance size of log nodes"
  default     = "large"
}

variable "load_test_root_disk_size" {
  description = "Default disk size for load testing nodes"
  default     = 20
}

variable "load_test_instance_type" {
  description = "Instance type of log nodes"
  default     = "c6g"
}

variable "load_test_instance_size" {
  description = "Instance size of log nodes"
  default     = "xlarge"
}

variable "metrics_root_disk_size" {
  description = "Default disk size for load testing nodes"
  default     = 20
}

variable "metrics_instance_type" {
  description = "Instance type of log nodes"
  default     = "c6g"
}

variable "metrics_instance_size" {
  description = "Instance size of log nodes"
  default     = "xlarge"
}

variable "wallet_node_instance_size" {
  description = "Instance type of wallet nodes"
  default     = "micro"
}

variable "volume_type" {
  description = "Type of volume to use for block devices"
  default     = "gp3"
}

variable "create_eip" {
  description = "Whether to create an Elastic IP for the instance"
  type        = bool
  default     = true
}

variable "mixer_size" {
  description = "Size of the mixer disk in GB"
  default     = "40"
}
