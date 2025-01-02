resource "aws_security_group" "default" {
  name        = "${terraform.workspace}-ssh"
  description = "ssh access"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # ET SSH access from anywhere
  ingress {
    from_port   = 2022
    to_port     = 2022
    protocol    = "tcp"
    description = "ET SSH"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Docker API
  ingress {
    from_port   = var.docker_port
    to_port     = var.docker_port
    protocol    = "tcp"
    description = "Docker API"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = flatten([
      "0.0.0.0/0",
      aws_subnet.public.*.cidr_block,
    ])
  }

  tags = {
    Name        = "dn-${terraform.workspace}-default"
    DashNetwork = terraform.workspace
  }
}

# dashd nodes not accessible from the public internet
resource "aws_security_group" "dashd_private" {
  name        = "${terraform.workspace}-dashd-private"
  description = "dashd private node"
  vpc_id      = aws_vpc.default.id

  # Dash Core access
  ingress {
    from_port   = var.dashd_port
    to_port     = var.dashd_port
    protocol    = "tcp"
    description = "DashCore P2P"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
    ])
  }

  # DashCore RPC access
  ingress {
    from_port   = var.dashd_rpc_port
    to_port     = var.dashd_rpc_port
    protocol    = "tcp"
    description = "DashCore RPC"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # DashCore ZMQ acess
  ingress {
    from_port   = var.dashd_zmq_port
    to_port     = var.dashd_zmq_port
    protocol    = "tcp"
    description = "DashCore ZMQ"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  tags = {
    Name        = "dn-${terraform.workspace}-dashd-private"
    DashNetwork = terraform.workspace
  }
}

# dashd node accessible from the public internet
resource "aws_security_group" "dashd_public" {
  name        = "${terraform.workspace}-dashd-public"
  description = "dashd public network"
  vpc_id      = aws_vpc.default.id

  # Dash Core access
  ingress {
    from_port   = var.dashd_port
    to_port     = var.dashd_port
    protocol    = "tcp"
    description = "DashCore P2P"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # DashCore RPC access
  ingress {
    from_port   = var.dashd_rpc_port
    to_port     = var.dashd_rpc_port
    protocol    = "tcp"
    description = "DashCore RPC"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # DashCore ZMQ acess
  ingress {
    from_port   = var.dashd_zmq_port
    to_port     = var.dashd_zmq_port
    protocol    = "tcp"
    description = "DashCore ZMQ"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  tags = {
    Name        = "dn-${terraform.workspace}-dashd-public"
    DashNetwork = terraform.workspace
  }
}

resource "aws_security_group" "http" {
  name        = "${terraform.workspace}-http"
  description = "web node"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = var.faucet_port
    to_port     = var.faucet_port
    protocol    = "tcp"
    description = "Faucet"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # Insight Explorer
  ingress {
    from_port   = var.insight_port
    to_port     = var.insight_port
    protocol    = "tcp"
    description = "Insight Explorer"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Insight Explorer HTTPS
  ingress {
    from_port   = var.insight_https_port
    to_port     = var.insight_https_port
    protocol    = "tcp"
    description = "Insight Explorer HTTPS"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name        = "dn-${terraform.workspace}-http"
    DashNetwork = terraform.workspace
  }
}

resource "aws_security_group" "logs" {
  name        = "${terraform.workspace}-logs"
  description = "logs node"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = var.kibana_port
    to_port     = var.kibana_port
    protocol    = "tcp"
    description = "Kibana"

    cidr_blocks = flatten([
      "0.0.0.0/0",
    ])
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    description = "Elasticsearch HTTP"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    description = "Elasticsearch TCP transport"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  tags = {
    Name        = "dn-${terraform.workspace}-logs"
    DashNetwork = terraform.workspace
  }
}

# dashd node accessible from the public internet
resource "aws_security_group" "hp_masternode" {
  name        = "${terraform.workspace}-hp-masternode"
  description = "hp masternode"
  vpc_id      = aws_vpc.default.id

  # Insight API access
  ingress {
    from_port   = var.insight_port
    to_port     = var.insight_port
    protocol    = "tcp"
    description = "Insight API"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # Drive
  ingress {
    from_port   = var.drive_port
    to_port     = var.drive_port
    protocol    = "tcp"
    description = "Drive"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # DAPI
  ingress {
    from_port   = var.gateway_port
    to_port     = var.gateway_port
    protocol    = "tcp"
    description = "DAPI"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Tendermint P2P
  ingress {
    from_port   = var.tendermint_p2p_port
    to_port     = var.tendermint_p2p_port
    protocol    = "tcp"
    description = "Tendermint P2P"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port   = var.grovedb_visualizer_port
    to_port     = var.grovedb_visualizer_port
    protocol    = "tcp"
    description = "GroveDB visualizer"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Tenderdash prometheus
  ingress {
    from_port   = 36660
    to_port     = 36660
    protocol    = "tcp"
    description = "Tenderdash prometheus"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

  # Tendermint ABCI
  ingress {
    from_port   = var.tendermint_abci_port
    to_port     = var.tendermint_abci_port
    protocol    = "tcp"
    description = "Tendermint ABCI"

    cidr_blocks = flatten([
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # Add ingress rule for port 9090
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    description = "Internal service on port 9090"
    cidr_blocks = ["10.0.0.0/16"]
 }

# Add ingress rule for port 9102
  ingress {
    from_port   = 9102
    to_port     = 9102
    protocol    = "tcp"
    description = "Internal service on port 9102"
    cidr_blocks = ["10.0.0.0/16"]
  }

 # Add ingress rule for port 29090
  ingress {
    from_port   = 29090
    to_port     = 29090
    protocol    = "tcp"
    description = "Internal service on port 9102"
    cidr_blocks = ["10.0.0.0/16"]
  }




  # Tendermint RPC
  ingress {
    from_port   = var.tendermint_rpc_port
    to_port     = var.tendermint_rpc_port
    protocol    = "tcp"
    description = "Tendermint RPC"

    cidr_blocks = flatten([
      aws_subnet.public.*.cidr_block,
      "${aws_eip.vpn[0].public_ip}/32",
    ])
  }

  # ZeroSSL IP verification
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "ZeroSSL IP verification"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode"
    DashNetwork = terraform.workspace
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name   = "${terraform.workspace}-elb"
  vpc_id = aws_vpc.default.id

  # Faucet
  ingress {
    from_port   = var.faucet_port
    to_port     = var.faucet_port
    protocol    = "tcp"
    description = "Faucet"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Faucet HTTPS
  ingress {
    from_port   = var.faucet_https_port
    to_port     = var.faucet_https_port
    protocol    = "tcp"
    description = "Faucet HTTPS"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Insight Explorer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Insight Explorer"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # Insight Explorer HTTPS
  ingress {
    from_port   = var.insight_https_port
    to_port     = var.insight_https_port
    protocol    = "tcp"
    description = "Insight Explorer HTTPS"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name        = "dn-${terraform.workspace}-elb"
    DashNetwork = terraform.workspace
  }
}

resource "aws_security_group" "vpn" {
  count = var.vpn_enabled ? 1 : 0

  name        = "${terraform.workspace}-vpn"
  description = "vpn client access"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # VPN Client
  ingress {
    from_port   = var.vpn_port
    to_port     = var.vpn_port
    protocol    = "udp"
    description = "VPN client"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = flatten([
      "0.0.0.0/0",
      aws_subnet.public.*.cidr_block,
    ])
  }

  tags = {
    Name        = "dn-${terraform.workspace}-vpn"
    DashNetwork = terraform.workspace
  }
}

resource "aws_security_group" "seed" {
  name        = "${terraform.workspace}-seed"
  description = "seed node"
  vpc_id      = aws_vpc.default.id

  # Tendermint P2P
  ingress {
    from_port   = var.tendermint_p2p_port
    to_port     = var.tendermint_p2p_port
    protocol    = "tcp"
    description = "Tendermint P2P"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name        = "dn-${terraform.workspace}-seed"
    DashNetwork = terraform.workspace
  }
}

resource "aws_security_group" "prometheus" {
  name        = "${terraform.workspace}-prometheus"
  description = "prometheus"
  vpc_id      = aws_vpc.default.id

  # Prometheus
  ingress {
    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    protocol    = "tcp"
    description = "Prometheus port"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name        = "dn-${terraform.workspace}-seed"
    DashNetwork = terraform.workspace
  }
}
