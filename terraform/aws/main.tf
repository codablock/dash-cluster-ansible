# Specify backend and image details
terraform {
  backend "s3" {
  }
}

data "aws_availability_zones" "available" {
  exclude_names = ["us-west-2d"]
  state         = "available"
}

data "aws_ami" "ubuntu_amd" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-2023*",
    ]
  }

  owners = [
    "099720109477",
  ]
  # Canonical
}

data "aws_ami" "ubuntu_arm" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-2023*",
    ]
  }

  owners = [
    "099720109477",
  ]
  # Canonical
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "dn-${terraform.workspace}"
    DashNetwork = terraform.workspace
  }
}

# Create an internet gateway to give our subnets access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name        = "dn-${terraform.workspace}"
    DashNetwork = terraform.workspace
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create subnets to launch our instances into
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.subnet_public_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name        = "${terraform.workspace}-public${count.index}"
    DashNetwork = terraform.workspace
    Tier        = "Public"
  }
}

data "aws_route53_zone" "main_domain" {
  count = length(var.main_domain) > 1 ? 1 : 0
  name  = var.main_domain
}

resource "aws_elb" "web" {
  name = var.public_network_name

  subnets = aws_subnet.public.*.id

  count = var.web_count >= 1 ? 1 : 0

  security_groups = [
    aws_security_group.elb.id,
  ]

  instances = [
    aws_instance.web[0].id,
  ]

  listener {
    instance_port     = var.faucet_port
    instance_protocol = "http"
    lb_port           = var.faucet_port
    lb_protocol       = "http"
  }

  listener {
    instance_port      = var.faucet_port
    instance_protocol  = "http"
    lb_port            = var.faucet_https_port
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate_validation.faucet.certificate_arn
  }

  listener {
    instance_port     = var.insight_port
    instance_protocol = "http"
    lb_port           = var.insight_port
    lb_protocol       = "http"
  }

  listener {
    instance_port      = var.insight_port
    instance_protocol  = "http"
    lb_port            = var.insight_https_port
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate_validation.insight.certificate_arn
  }

  health_check {
    healthy_threshold   = 2
    interval            = 20
    target              = "HTTP:80/"
    timeout             = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "dn-${terraform.workspace}-web"
    DashNetwork = terraform.workspace
  }
}

resource "aws_lb" "seed" {
  name                       = "${var.public_network_name}-nlb-seed"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = false
}

resource "aws_lb_listener" "seed" {
  load_balancer_arn = aws_lb.seed.arn
  port              = var.gateway_port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.seed.arn
  alpn_policy       = "HTTP2Optional"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.seed.arn
  }
}

resource "aws_lb_target_group" "seed" {
  name     = "${var.public_network_name}-tg-seed"
  port     = var.gateway_port
  protocol = "TLS"
  vpc_id   = aws_vpc.default.id

  health_check {
    interval            = 30
    port                = var.gateway_port
    timeout             = 10
    protocol            = "HTTPS"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group_attachment" "amd_hpmns" {
  count            = var.hp_masternode_amd_count
  target_group_arn = aws_lb_target_group.seed.arn
  target_id        = aws_instance.hp_masternode_amd[count.index].id
}

resource "aws_lb_target_group_attachment" "arm_hpmns" {
  count            = var.hp_masternode_arm_count
  target_group_arn = aws_lb_target_group.seed.arn
  target_id        = aws_instance.hp_masternode_arm[count.index].id
}

resource "aws_route53_record" "seeds" {
  count   = length(var.main_domain) > 1 ? 5 : 0
  zone_id = data.aws_route53_zone.main_domain[0].zone_id
  name    = "seed-${count.index + 1}.${var.public_network_name}.${var.main_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.seed.dns_name
    zone_id                = aws_lb.seed.zone_id
    # TODO: enable health checks
    # https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--ready
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "faucet" {
  domain_name       = "faucet.${var.public_network_name}.${var.main_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "faucet_validation" {
  for_each = {
    for dvo in aws_acm_certificate.faucet.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main_domain[0].zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "faucet" {
  certificate_arn         = aws_acm_certificate.faucet.arn
  validation_record_fqdns = [for record in aws_route53_record.faucet_validation : record.fqdn]
}

resource "aws_route53_record" "faucet" {
  zone_id = data.aws_route53_zone.main_domain[count.index].zone_id
  name    = "faucet.${var.public_network_name}.${var.main_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.web[count.index].dns_name]

  count = length(var.main_domain) > 1 ? 1 : 0
}

resource "aws_acm_certificate" "insight" {
  domain_name       = "insight.${var.public_network_name}.${var.main_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "insight_validation" {
  for_each = {
    for dvo in aws_acm_certificate.insight.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main_domain[0].zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "insight" {
  certificate_arn         = aws_acm_certificate.insight.arn
  validation_record_fqdns = [for record in aws_route53_record.insight_validation : record.fqdn]
}

resource "aws_route53_record" "insight" {
  zone_id = data.aws_route53_zone.main_domain[count.index].zone_id
  name    = "insight.${var.public_network_name}.${var.main_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.web[count.index].dns_name]

  count = length(var.main_domain) > 1 ? 1 : 0
}

resource "aws_route53_record" "metrics" {
  zone_id = data.aws_route53_zone.main_domain[0].zone_id
  name    = "metrics.${var.public_network_name}.networks.${var.main_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.web[count.index].dns_name]
  count   = length(var.main_domain) > 1 ? 1 : 0
}

resource "aws_route53_record" "logs" {
  zone_id = data.aws_route53_zone.main_domain[count.index].zone_id
  name    = "logs.${var.public_network_name}.${var.main_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.logs[count.index].public_ip]

  count = length(var.main_domain) > 1 ? 1 : 0
}

locals {
  dns_record_length = 10 // recommended number of hosts per A record. Other way there might be problems with resolving of seeds in some regions.
}

# shuffle hpmn ips only
resource "random_shuffle" "dns_ips" {
  input = concat(
    var.create_eip ? aws_eip.hpmn_arm_eip.*.public_ip : aws_instance.hp_masternode_arm.*.public_ip,
    var.create_eip ? aws_eip.hpmn_amd_eip.*.public_ip : aws_instance.hp_masternode_amd.*.public_ip
  )
  result_count = length(
    concat(
      var.create_eip ? aws_eip.hpmn_arm_eip.*.public_ip : aws_instance.hp_masternode_arm.*.public_ip,
      var.create_eip ? aws_eip.hpmn_amd_eip.*.public_ip : aws_instance.hp_masternode_amd.*.public_ip
    )
  ) > local.dns_record_length ? local.dns_record_length : length(
    concat(
      var.create_eip ? aws_eip.hpmn_arm_eip.*.public_ip : aws_instance.hp_masternode_arm.*.public_ip,
      var.create_eip ? aws_eip.hpmn_amd_eip.*.public_ip : aws_instance.hp_masternode_amd.*.public_ip
    )
  )
}

# `seed-n` type addresses are dapi endpoints

resource "aws_acm_certificate" "seed" {
  domain_name       = "seed-1.${var.public_network_name}.${var.main_domain}"
  validation_method = "DNS"

  subject_alternative_names = [
    "seed-2.${var.public_network_name}.${var.main_domain}",
    "seed-3.${var.public_network_name}.${var.main_domain}",
    "seed-4.${var.public_network_name}.${var.main_domain}",
    "seed-5.${var.public_network_name}.${var.main_domain}"
  ]

  tags = {
    Name = "seed.${var.public_network_name}.${var.main_domain}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "seed_validation" {
  for_each = {
    for dvo in aws_acm_certificate.seed.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main_domain[0].zone_id
}

resource "aws_acm_certificate_validation" "seed" {
  certificate_arn         = aws_acm_certificate.seed.arn
  validation_record_fqdns = [for record in aws_route53_record.seed_validation : record.fqdn]
}

resource "aws_key_pair" "auth" {
  key_name   = "dn-${terraform.workspace}-auth"
  public_key = file(var.public_key_path)
}

resource "aws_eip" "vpn" {

  count = var.vpn_enabled ? 1 : 0

  instance = aws_instance.vpn[0].id

  tags = {
    Name        = "dn-${terraform.workspace}-vpn"
    DashNetwork = terraform.workspace
  }
}

