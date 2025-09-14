# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Security Group for Cloudflare tunnel EC2 instances
resource "aws_security_group" "cloudflared" {
  name_prefix = "${var.environment}-cf-tunnel-sg-"
  description = "Security group for Cloudflare tunnel EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-sg"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Egress rule - Allow all outbound traffic
resource "aws_security_group_rule" "cloudflared_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.cloudflared.id
  description       = "Allow all outbound traffic"
}

# Egress rule - HTTPS to Cloudflare (primary)
resource "aws_security_group_rule" "cloudflared_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloudflared.id
  description       = "HTTPS traffic to Cloudflare edge"
}

# Egress rule - DNS resolution
resource "aws_security_group_rule" "cloudflared_egress_dns" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloudflared.id
  description       = "DNS resolution"
}

# Egress rule - Cloudflare tunnel protocol (7844)
resource "aws_security_group_rule" "cloudflared_egress_tunnel" {
  type              = "egress"
  from_port         = 7844
  to_port           = 7844
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloudflared.id
  description       = "Cloudflare tunnel protocol"
}

# Ingress rule - Allow SSM Session Manager (optional)
resource "aws_security_group_rule" "cloudflared_ingress_ssm" {
  count = var.enable_ssm_session_manager ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloudflared.id
  description       = "HTTPS for SSM Session Manager"
}

# Ingress rule - Custom ingress rules (if any)
resource "aws_security_group_rule" "cloudflared_ingress_custom" {
  count = length(var.ingress_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks
  security_group_id = aws_security_group.cloudflared.id
  description       = "Custom ingress rules"
}

# Security Group for VPC endpoints (if using private subnets)
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_ssm_session_manager ? 1 : 0

  name_prefix = "${var.environment}-cf-tunnel-vpc-endpoints-sg-"
  description = "Security group for VPC endpoints used by Cloudflare tunnel instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-vpc-endpoints-sg"
    Environment = var.environment
    Service     = "cloudflare-tunnel-vpc-endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoint ingress from EC2 instances
resource "aws_security_group_rule" "vpc_endpoints_ingress_from_ec2" {
  count = var.enable_ssm_session_manager ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cloudflared.id
  security_group_id        = aws_security_group.vpc_endpoints[0].id
  description              = "HTTPS from EC2 instances"
}

# VPC Endpoint egress
resource "aws_security_group_rule" "vpc_endpoints_egress" {
  count = var.enable_ssm_session_manager ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoints[0].id
  description       = "Allow all outbound traffic"
}

# Create VPC endpoints for SSM if needed
resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_ssm_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.environment}-ssm-endpoint"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

resource "aws_vpc_endpoint" "ssm_messages" {
  count = var.enable_ssm_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.environment}-ssmmessages-endpoint"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

resource "aws_vpc_endpoint" "ec2_messages" {
  count = var.enable_ssm_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.environment}-ec2messages-endpoint"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

resource "aws_vpc_endpoint" "kms" {
  count = var.enable_ssm_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.environment}-kms-endpoint"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Data source for subnet information
data "aws_subnet" "private" {
  count = var.enable_network_acls ? length(var.private_subnet_ids) : 0
  id    = var.private_subnet_ids[count.index]
}

# Data source for network ACLs
data "aws_network_acls" "private" {
  count = var.enable_network_acls ? 1 : 0

  filter {
    name   = "association.subnet-id"
    values = var.private_subnet_ids
  }
}

# Network ACL rules (optional, for additional security)
resource "aws_network_acl_rule" "cloudflared_outbound_https" {
  count = var.enable_network_acls && length(data.aws_network_acls.private[0].ids) > 0 ? 1 : 0

  network_acl_id = data.aws_network_acls.private[0].ids[0]
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "cloudflared_outbound_tunnel" {
  count = var.enable_network_acls && length(data.aws_network_acls.private[0].ids) > 0 ? 1 : 0

  network_acl_id = data.aws_network_acls.private[0].ids[0]
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 7844
  to_port        = 7844
}

# Add variable for network ACLs
variable "enable_network_acls" {
  description = "Enable network ACL rules for additional security"
  type        = bool
  default     = false
}
