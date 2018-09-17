variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "dashd_port" {
  description = "Port for Dash Core nodes"
  default     = "20001"
}

variable "dashd_rpc_port" {
  description = "Port for Dash RPC interface"
  default     = "20002"
}

variable "dashd_zmq_port" {
  description = "Port for Dash Zmq interface"
  default     = "29998"
}

variable "ipfs_swarm_port" {
  description = "IPFS Swarm port"
  default     = "4001"
}

variable "ipfs_api_port" {
  description = "IPFS API port"
  default     = "5001"
}

variable "insight_port" {
  description = "Insight API port"
  default     = "3001"
}

variable "drive_port" {
  description = "Insight API port"
  default     = "6000"
}

variable "dapi_port" {
  description = "Insight API port"
  default     = "3000"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "private_subnet" {
  default = "10.0.0.0/16"
}

variable "node_count" {
  default = 1
}

variable "miner_count" {
  default = 1
}

variable "masternode_count" {
  default = 3
}

variable "wallet_count" {
  description = "number of wallet nodes to create. must be at least 2"
  default     = 2
}

variable "web_count" {
  default = 1
}

variable "vpn_enabled" {
  default     = true
  description = "setup instance for vpn"
}
