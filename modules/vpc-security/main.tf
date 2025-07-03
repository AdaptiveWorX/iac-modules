# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC NACLs Module - Manages Network Access Control Lists

# Default NACL - Deny all traffic as security fallback
resource "aws_default_network_acl" "default" {
  default_network_acl_id = var.default_network_acl_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nacl-default-deny-all"
      Purpose     = "Security fallback - Deny all traffic"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Public NACL
resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nacl-public"
      Tier        = "public"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Private NACL
resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nacl-private"
      Tier        = "private"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Data NACL
resource "aws_network_acl" "data" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nacl-data"
      Tier        = "data"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Public NACL Rules - Inbound
resource "aws_network_acl_rule" "public_inbound_http_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_https_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# SSH access - restricted to known IP ranges or disabled by default
resource "aws_network_acl_rule" "public_inbound_ssh_ipv4" {
  count          = var.enable_ssh_access ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ssh_allowed_cidr_blocks[0]
  from_port      = 22
  to_port        = 22
}

# Additional SSH rules for multiple allowed CIDR blocks
resource "aws_network_acl_rule" "public_inbound_ssh_ipv4_additional" {
  count          = var.enable_ssh_access ? length(var.ssh_allowed_cidr_blocks) - 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 121 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ssh_allowed_cidr_blocks[count.index + 1]
  from_port      = 22
  to_port        = 22
}

# RDP access - restricted to known IP ranges or disabled by default
resource "aws_network_acl_rule" "public_inbound_rdp_ipv4" {
  count          = var.enable_rdp_access ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.rdp_allowed_cidr_blocks[0]
  from_port      = 3389
  to_port        = 3389
}

# Additional RDP rules for multiple allowed CIDR blocks
resource "aws_network_acl_rule" "public_inbound_rdp_ipv4_additional" {
  count          = var.enable_rdp_access ? length(var.rdp_allowed_cidr_blocks) - 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 131 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.rdp_allowed_cidr_blocks[count.index + 1]
  from_port      = 3389
  to_port        = 3389
}

# ICMP/Ping support - Allow ICMP echo request/reply for network troubleshooting
resource "aws_network_acl_rule" "public_inbound_icmp_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 140
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = -1
  icmp_code      = -1
}

# ICMPv6 support for public subnets
resource "aws_network_acl_rule" "public_inbound_icmp_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.public.id
  rule_number        = 141
  egress             = false
  protocol           = "58"  # ICMPv6 protocol number
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
  icmp_type          = -1
  icmp_code          = -1
}

resource "aws_network_acl_rule" "public_inbound_ephemeral_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Public NACL Rules - Inbound IPv6
resource "aws_network_acl_rule" "public_inbound_http_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.public.id
  rule_number        = 101
  egress             = false
  protocol           = "tcp"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
  from_port          = 80
  to_port            = 80
}

resource "aws_network_acl_rule" "public_inbound_https_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.public.id
  rule_number        = 111
  egress             = false
  protocol           = "tcp"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
  from_port          = 443
  to_port            = 443
}

resource "aws_network_acl_rule" "public_inbound_ephemeral_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.public.id
  rule_number        = 201
  egress             = false
  protocol           = "tcp"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
  from_port          = 1024
  to_port            = 65535
}

# Public NACL Rules - Outbound
resource "aws_network_acl_rule" "public_outbound_all_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_outbound_all_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.public.id
  rule_number        = 101
  egress             = true
  protocol           = "-1"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
}

# Private NACL Rules - Inbound
resource "aws_network_acl_rule" "private_inbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# ICMP/Ping support for private subnets - Allow from VPC CIDR
resource "aws_network_acl_rule" "private_inbound_icmp_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 150
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  icmp_type      = -1
  icmp_code      = -1
}

# ICMPv6 support for private subnets
resource "aws_network_acl_rule" "private_inbound_icmp_ipv6" {
  count              = var.enable_ipv6 && var.vpc_ipv6_cidr != null ? 1 : 0
  network_acl_id     = aws_network_acl.private.id
  rule_number        = 151
  egress             = false
  protocol           = "58"  # ICMPv6 protocol number
  rule_action        = "allow"
  ipv6_cidr_block    = var.vpc_ipv6_cidr
  icmp_type          = -1
  icmp_code          = -1
}

resource "aws_network_acl_rule" "private_inbound_ephemeral_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_inbound_vpc_ipv6" {
  count              = var.enable_ipv6 && var.vpc_ipv6_cidr != null ? 1 : 0
  network_acl_id     = aws_network_acl.private.id
  rule_number        = 101
  egress             = false
  protocol           = "-1"
  rule_action        = "allow"
  ipv6_cidr_block    = var.vpc_ipv6_cidr
}

resource "aws_network_acl_rule" "private_inbound_ephemeral_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.private.id
  rule_number        = 201
  egress             = false
  protocol           = "tcp"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
  from_port          = 1024
  to_port            = 65535
}

# Private NACL Rules - Outbound
resource "aws_network_acl_rule" "private_outbound_all_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_outbound_all_ipv6" {
  count              = var.enable_ipv6 ? 1 : 0
  network_acl_id     = aws_network_acl.private.id
  rule_number        = 101
  egress             = true
  protocol           = "-1"
  rule_action        = "allow"
  ipv6_cidr_block    = "::/0"
}

# Data NACL Rules - Inbound
resource "aws_network_acl_rule" "data_inbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# ICMP/Ping support for data subnets - Allow from VPC CIDR
resource "aws_network_acl_rule" "data_inbound_icmp_ipv4" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 150
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  icmp_type      = -1
  icmp_code      = -1
}

# ICMPv6 support for data subnets
resource "aws_network_acl_rule" "data_inbound_icmp_ipv6" {
  count              = var.enable_ipv6 && var.vpc_ipv6_cidr != null ? 1 : 0
  network_acl_id     = aws_network_acl.data.id
  rule_number        = 151
  egress             = false
  protocol           = "58"  # ICMPv6 protocol number
  rule_action        = "allow"
  ipv6_cidr_block    = var.vpc_ipv6_cidr
  icmp_type          = -1
  icmp_code          = -1
}

resource "aws_network_acl_rule" "data_inbound_vpc_ipv6" {
  count              = var.enable_ipv6 && var.vpc_ipv6_cidr != null ? 1 : 0
  network_acl_id     = aws_network_acl.data.id
  rule_number        = 101
  egress             = false
  protocol           = "-1"
  rule_action        = "allow"
  ipv6_cidr_block    = var.vpc_ipv6_cidr
}

# Data NACL Rules - Outbound
resource "aws_network_acl_rule" "data_outbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "data_outbound_vpc_ipv6" {
  count              = var.enable_ipv6 && var.vpc_ipv6_cidr != null ? 1 : 0
  network_acl_id     = aws_network_acl.data.id
  rule_number        = 101
  egress             = true
  protocol           = "-1"
  rule_action        = "allow"
  ipv6_cidr_block    = var.vpc_ipv6_cidr
}

# NACL Associations
resource "aws_network_acl_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  network_acl_id = aws_network_acl.private.id
}

resource "aws_network_acl_association" "data" {
  count          = length(var.data_subnet_ids)
  subnet_id      = var.data_subnet_ids[count.index]
  network_acl_id = aws_network_acl.data.id
}
