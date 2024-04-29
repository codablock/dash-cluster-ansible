resource "aws_instance" "web" {
  count = var.web_count

  connection {
    host = coalesce(self.public_ip, self.private_ip)
    type = "ssh"
    user = "ubuntu"
  }

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = var.main_host_arch == "arm64" ? "t4g.small" : "t3.small"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.core_node_disk_size
    volume_type = var.volume_type
  }

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.http.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  volume_tags = {
    Name        = "dn-${terraform.workspace}-web-${count.index + 1}"
    Hostname    = "web-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-web-${count.index + 1}"
    Hostname    = "web-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# dashd wallet nodes (for faucet and masternode collaterals)
resource "aws_instance" "dashd_wallet" {
  count = var.wallet_count

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = join(".", [var.main_host_arch == "arm64" ? "t4g" : "t3", var.wallet_node_instance_size])
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.core_node_disk_size
    volume_type = var.volume_type
  }

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_private.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  volume_tags = {
    Name        = "dn-${terraform.workspace}-dashd-wallet-${count.index + 1}"
    Hostname    = "dashd-wallet-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-dashd-wallet-${count.index + 1}"
    Hostname    = "dashd-wallet-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

# dashd full nodes
resource "aws_instance" "seed_node" {
  count = var.seed_count

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = var.main_host_arch == "arm64" ? "t4g.small" : "t3.small"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
    aws_security_group.hp_masternode.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  root_block_device {
    volume_size = var.hpmn_node_disk_size
    volume_type = var.volume_type
  }

  volume_tags = {
    Name        = "dn-${terraform.workspace}-seed-${count.index + 1}"
    Hostname    = "seed-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-seed-${count.index + 1}"
    Hostname    = "seed-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

# cpu miners (not running a node)
resource "aws_instance" "miner" {
  count = var.miner_count

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = var.main_host_arch == "arm64" ? "t4g.small" : "t3.small"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.core_node_disk_size
    volume_type = var.volume_type
  }

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_private.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  volume_tags = {
    Name        = "dn-${terraform.workspace}-miner-${count.index + 1}"
    Hostname    = "miner-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-miner-${count.index + 1}"
    Hostname    = "miner-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

# masternodes (amd)
resource "aws_instance" "masternode_amd" {
  count = var.masternode_amd_count

  ami                  = data.aws_ami.ubuntu_amd.id
  instance_type        = "t3.small"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  root_block_device {
    volume_size = var.mn_node_disk_size
    volume_type = var.volume_type
  }

  volume_tags = {
    Name        = "dn-${terraform.workspace}-masternode-${count.index + 1}"
    Hostname    = "masternode-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-masternode-${count.index + 1}"
    Hostname    = "masternode-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}


# masternodes (arm)
resource "aws_instance" "masternode_arm" {
  count = var.masternode_arm_count

  ami                  = data.aws_ami.ubuntu_arm.id
  instance_type        = "t4g.small"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  root_block_device {
    volume_size = var.mn_node_disk_size
    volume_type = var.volume_type
  }

  volume_tags = {
    Name        = "dn-${terraform.workspace}-masternode-${count.index + var.masternode_amd_count + 1}"
    Hostname    = "masternode-${count.index + var.masternode_amd_count + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-masternode-${count.index + var.masternode_amd_count + 1}"
    Hostname    = "masternode-${count.index + var.masternode_amd_count + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_eip" "hpmn_arm_eip" {
  instance = null
  count = var.create_eip ? var.hp_masternode_arm_count : 0
  tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-arm-${count.index+1}"
    DashNetwork = terraform.workspace
  }
}

resource "aws_eip" "hpmn_amd_eip" {
  instance = null
  count = var.create_eip ? var.hp_masternode_amd_count : 0
  tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-amd-${count.index+1}"
    DashNetwork = terraform.workspace
  }
}

resource "aws_instance" "hp_masternode_amd" {
  count = var.hp_masternode_amd_count

  ami                  = data.aws_ami.ubuntu_amd.id
  instance_type        = "t3.medium"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
    aws_security_group.hp_masternode.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  root_block_device {
    volume_size = var.hpmn_node_disk_size
    volume_type = var.volume_type
  }

  volume_tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-${count.index + 1}"
    Hostname    = "hp-masternode-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-${count.index + 1}"
    Hostname    = "hp-masternode-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}


resource "aws_instance" "hp_masternode_arm" {
  count = var.hp_masternode_arm_count

  ami                  = data.aws_ami.ubuntu_arm.id
  instance_type        = "t4g.medium"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
    aws_security_group.hp_masternode.id,
  ]

  subnet_id = element(aws_subnet.public.*.id, count.index)

  root_block_device {
    volume_size = var.hpmn_node_disk_size
    volume_type = var.volume_type
  }

  volume_tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-${count.index + var.hp_masternode_amd_count + 1}"
    Hostname    = "hp-masternode-${count.index + var.hp_masternode_amd_count + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-hp-masternode-${count.index + var.hp_masternode_amd_count + 1}"
    Hostname    = "hp-masternode-${count.index + var.hp_masternode_amd_count + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_eip_association" "arm_eip_assoc" {
  count = var.create_eip ? var.hp_masternode_arm_count : 0

  instance_id   = aws_instance.hp_masternode_arm[count.index].id
  allocation_id = aws_eip.hpmn_arm_eip[count.index].id
}

resource "aws_eip_association" "amd_eip_assoc" {
  count = var.create_eip ? var.hp_masternode_amd_count : 0

  instance_id   = aws_instance.hp_masternode_amd[count.index].id
  allocation_id = aws_eip.hpmn_amd_eip[count.index].id
}


resource "aws_instance" "vpn" {
  count = var.vpn_enabled ? 1 : 0

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = var.main_host_arch == "arm64" ? "t4g.nano" : "t3.nano"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  subnet_id = element(aws_subnet.public.*.id, count.index)

  vpc_security_group_ids = [
    aws_security_group.vpn[0].id,
  ]

  volume_tags = {
    Name        = "dh-${terraform.workspace}-vpn"
    Hostname    = "vpn"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dh-${terraform.workspace}-vpn"
    Hostname    = "vpn"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_instance" "mixer" {
  count = var.mixer_count

  ami                  = var.main_host_arch == "arm64" ? data.aws_ami.ubuntu_arm.id : data.aws_ami.ubuntu_amd.id
  instance_type        = var.main_host_arch == "arm64" ? "t4g.medium" : "t3.medium"
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  subnet_id = element(aws_subnet.public.*.id, count.index)

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.dashd_public.id,
  ]

  volume_tags = {
    Name        = "dh-${terraform.workspace}-mixer-${count.index + 1}"
    Hostname    = "mixer-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dh-${terraform.workspace}-mixer-${count.index + 1}"
    Hostname    = "mixer-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  root_block_device {
    volume_size = 40
    volume_type = var.volume_type
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_instance" "logs" {
  count = var.logs_count

  ami                  = data.aws_ami.ubuntu_arm.id
  instance_type        = join(".", [var.logs_node_instance_type, var.logs_node_instance_size])
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.logs_node_root_disk_size
    volume_type = var.volume_type
  }

  subnet_id = element(aws_subnet.public.*.id, count.index)

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.logs.id,
  ]

  volume_tags = {
    Name        = "dn-${terraform.workspace}-logs-${count.index + 1}"
    Hostname    = "logs-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-logs-${count.index + 1}"
    Hostname    = "logs-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "load_test" {
  count = var.load_test_count

  ami                  = data.aws_ami.ubuntu_arm.id
  instance_type        = join(".", [var.load_test_instance_type, var.load_test_instance_size])
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.load_test_root_disk_size
    volume_type = var.volume_type
  }

  subnet_id = element(aws_subnet.public.*.id, count.index)

  vpc_security_group_ids = [
    aws_security_group.default.id,
  ]

  volume_tags = {
    Name        = "dn-${terraform.workspace}-load-test-${count.index + 1}"
    Hostname    = "load-test-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-load-test-${count.index + 1}"
    Hostname    = "load-test-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_instance" "metrics" {
  count = var.metrics_count

  ami                  = data.aws_ami.ubuntu_arm.id
  instance_type        = join(".", [var.metrics_instance_type, var.metrics_instance_size])
  key_name             = aws_key_pair.auth.id
  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_size = var.metrics_root_disk_size
    volume_type = var.volume_type
  }

  subnet_id = element(aws_subnet.public.*.id, count.index)

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.prometheus.id,
  ]

  volume_tags = {
    Name        = "dn-${terraform.workspace}-prometheus-${count.index + 1}"
    Hostname    = "prometheus-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  tags = {
    Name        = "dn-${terraform.workspace}-prometheus-${count.index + 1}"
    Hostname    = "prometheus-${count.index + 1}"
    DashNetwork = terraform.workspace
  }

  lifecycle {
    ignore_changes = [ami]
  }

}
