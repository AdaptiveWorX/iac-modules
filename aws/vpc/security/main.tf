# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Security Module - Security Layer
# Consolidates: security groups, NACLs, and VPC peering
# This layer contains resources that change occasionally

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ============================================================================
# DATA SOURCES - Reference Foundation Layer
# ============================================================================

data "aws_vpc" "main" {
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Type = "public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Type = "private"
  }
}

data "aws_subnets" "data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Type = "database"
  }
}

data "aws_route_tables" "all" {
  vpc_id = data.aws_vpc.main.id
}

locals {
  vpc_id      = data.aws_vpc.main.id
  vpc_cidr    = data.aws_vpc.main.cidr_block
  vpc_ipv6_cidr = try(data.aws_vpc.main.ipv6_cidr_block, null)
  
  public_subnet_ids  = data.aws_subnets.public.ids
  private_subnet_ids = data.aws_subnets.private.ids
  data_subnet_ids    = data.aws_subnets.data.ids
  
  # Peering configuration
  peer_connections = { for idx, peer in var.peer_configs : 
    "${var.environment}-${var.aws_region}-to-${peer.region}" => {
      index        = idx
      peer_region  = peer.region
      peer_vpc_id  = peer.vpc_id
      peer_vpc_cidr = peer.vpc_cidr
    }
  }
}

# ============================================================================
# DEFAULT SECURITY GROUP AND NACL LOCKDOWN
# ============================================================================

# Default Security Group - Lock it down (deny all)
resource "aws_default_security_group" "default" {
  vpc_id = local.vpc_id

  # No ingress rules = deny all inbound
  # No egress rules = deny all outbound
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-default-sg-locked"
      Description = "Default security group - locked down (deny all)"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Get the default network ACL ID
data "aws_network_acls" "default" {
  vpc_id = data.aws_vpc.main.id
  
  filter {
    name   = "default"
    values = ["true"]
  }
}

# Default NACL - Deny all traffic as security fallback
resource "aws_default_network_acl" "default" {
  default_network_acl_id = tolist(data.aws_network_acls.default.ids)[0]

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

# ============================================================================
# NETWORK ACLS
# ============================================================================

# Public NACL
resource "aws_network_acl" "public" {
  vpc_id = local.vpc_id

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
  vpc_id = local.vpc_id

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
  vpc_id = local.vpc_id

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

# SSH access - restricted to known IP ranges
resource "aws_network_acl_rule" "public_inbound_ssh_ipv4" {
  count          = var.enable_ssh_access && length(var.ssh_allowed_cidr_blocks) > 0 ? length(var.ssh_allowed_cidr_blocks) : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ssh_allowed_cidr_blocks[count.index]
  from_port      = 22
  to_port        = 22
}

# RDP access - restricted to known IP ranges
resource "aws_network_acl_rule" "public_inbound_rdp_ipv4" {
  count          = var.enable_rdp_access && length(var.rdp_allowed_cidr_blocks) > 0 ? length(var.rdp_allowed_cidr_blocks) : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.rdp_allowed_cidr_blocks[count.index]
  from_port      = 3389
  to_port        = 3389
}

# ICMP/Ping support
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

# Ephemeral ports for return traffic
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

# Public NACL Rules - Outbound
resource "aws_network_acl_rule" "public_outbound_all_ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Private NACL Rules - Inbound
resource "aws_network_acl_rule" "private_inbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = local.vpc_cidr
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

# Private NACL Rules - Outbound
resource "aws_network_acl_rule" "private_outbound_all_ipv4" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Data NACL Rules - Inbound
resource "aws_network_acl_rule" "data_inbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = local.vpc_cidr
}

# Data NACL Rules - Outbound (only within VPC)
resource "aws_network_acl_rule" "data_outbound_vpc_ipv4" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = local.vpc_cidr
}

# NACL Associations
resource "aws_network_acl_association" "public" {
  count          = length(local.public_subnet_ids)
  subnet_id      = local.public_subnet_ids[count.index]
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "private" {
  count          = length(local.private_subnet_ids)
  subnet_id      = local.private_subnet_ids[count.index]
  network_acl_id = aws_network_acl.private.id
}

resource "aws_network_acl_association" "data" {
  count          = length(local.data_subnet_ids)
  subnet_id      = local.data_subnet_ids[count.index]
  network_acl_id = aws_network_acl.data.id
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Base security group for common rules
resource "aws_security_group" "base" {
  name_prefix = "${var.environment}-base-"
  description = "Base security group with common rules"
  vpc_id      = local.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-base-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Web security group
resource "aws_security_group" "web" {
  count = var.create_web_sg ? 1 : 0

  name_prefix = "${var.environment}-web-"
  description = "Security group for web servers"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-web-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Application security group
resource "aws_security_group" "app" {
  count = var.create_app_sg ? 1 : 0

  name_prefix = "${var.environment}-app-"
  description = "Security group for application servers"
  vpc_id      = local.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-app-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow web to app communication
resource "aws_security_group_rule" "web_to_app" {
  count = var.create_web_sg && var.create_app_sg ? 1 : 0

  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web[0].id
  security_group_id        = aws_security_group.app[0].id
  description              = "Allow traffic from web tier"
}

# Database security group
resource "aws_security_group" "database" {
  count = var.create_database_sg ? 1 : 0

  name_prefix = "${var.environment}-database-"
  description = "Security group for database servers"
  vpc_id      = local.vpc_id

  egress {
    description = "Allow outbound within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-database-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow app to database communication
resource "aws_security_group_rule" "app_to_database" {
  count = var.create_app_sg && var.create_database_sg ? 1 : 0

  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app[0].id
  security_group_id        = aws_security_group.database[0].id
  description              = "Allow traffic from app tier"
}

# Bastion/Jump host security group
resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name_prefix = "${var.environment}-bastion-"
  description = "Security group for bastion hosts"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.bastion_allowed_cidr_blocks
    content {
      description = "SSH from ${ingress.value}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-bastion-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# VPC PEERING (DISABLED - Requires cross-region configuration)
# ============================================================================

# NOTE: VPC Peering is currently disabled as it requires cross-region provider configuration.
# To enable peering:
# 1. Add a peer provider configuration in your terragrunt.hcl
# 2. Uncomment the resources below
# 3. Configure the peer_configs variable with target VPC details

# # VPC Peering Connection
# resource "aws_vpc_peering_connection" "main" {
#   for_each = local.peer_connections
#   
#   vpc_id        = local.vpc_id
#   peer_vpc_id   = each.value.peer_vpc_id
#   peer_region   = each.value.peer_region
#   auto_accept   = false  # Must be accepted in peer region
# 
#   tags = merge(
#     var.tags,
#     {
#       Name        = each.key
#       Environment = var.environment
#       Type        = "cross-region"
#       PeerRegion  = each.value.peer_region
#       ManagedBy   = "terraform"
#     }
#   )
# }

# # Accept the peering connection in the peer region
# resource "aws_vpc_peering_connection_accepter" "peer" {
#   for_each = local.peer_connections
#   
#   provider                  = aws.peer
#   vpc_peering_connection_id = aws_vpc_peering_connection.main[each.key].id
#   auto_accept               = true
# 
#   tags = merge(
#     var.tags,
#     {
#       Name        = "${each.key}-accepter"
#       Environment = var.environment
#       Type        = "cross-region"
#       ManagedBy   = "terraform"
#     }
#   )
# }

# # Configure peering connection options
# resource "aws_vpc_peering_connection_options" "requester" {
#   for_each = local.peer_connections
#   
#   vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer[each.key].id
# 
#   requester {
#     allow_remote_vpc_dns_resolution = true
#   }
# }

# resource "aws_vpc_peering_connection_options" "accepter" {
#   for_each = local.peer_connections
#   
#   provider                  = aws.peer
#   vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer[each.key].id
# 
#   accepter {
#     allow_remote_vpc_dns_resolution = true
#   }
# }

# # Routes in the current VPC to peer VPCs
# resource "aws_route" "to_peer" {
#   for_each = { for pair in setproduct(keys(local.peer_connections), tolist(data.aws_route_tables.all.ids)) : 
#     "${pair[0]}-${pair[1]}" => {
#       peer_key = pair[0]
#       route_table_id = pair[1]
#     }
#   }
#   
#   route_table_id            = each.value.route_table_id
#   destination_cidr_block    = local.peer_connections[each.value.peer_key].peer_vpc_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.main[each.value.peer_key].id
#   
#   depends_on = [aws_vpc_peering_connection_accepter.peer]
# }

# # Routes in peer VPCs back to current VPC
# resource "aws_route" "from_peer" {
#   for_each = { for pair in setproduct(keys(local.peer_connections), 
#     flatten([for p in var.peer_configs : p.route_table_ids])) : 
#     "${pair[0]}-${pair[1]}" => {
#       peer_key = pair[0]
#       route_table_id = pair[1]
#       peer_idx = index(keys(local.peer_connections), pair[0])
#     } if contains(var.peer_configs[index(keys(local.peer_connections), pair[0])].route_table_ids, pair[1])
#   }
#   
#   provider                  = aws.peer
#   route_table_id            = each.value.route_table_id
#   destination_cidr_block    = local.vpc_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.main[each.value.peer_key].id
#   
#   depends_on = [aws_vpc_peering_connection_accepter.peer]
# }
