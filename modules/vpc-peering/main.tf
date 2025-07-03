# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Peering Module - Manages cross-region VPC peering connections

locals {
  # Create a map of peer connections from the peer_configs input
  peer_connections = { for idx, peer in var.peer_configs : 
    "${var.environment}-${var.current_region}-to-${peer.region}" => {
      index        = idx
      peer_region  = peer.region
      peer_vpc_id  = peer.vpc_id
      peer_vpc_cidr = peer.vpc_cidr
    }
  }
}

# Data source to get accepter VPC details
data "aws_vpc" "peer" {
  for_each = local.peer_connections
  
  provider = aws.peer
  id       = each.value.peer_vpc_id
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "main" {
  for_each = local.peer_connections
  
  vpc_id        = var.vpc_id
  peer_vpc_id   = each.value.peer_vpc_id
  peer_region   = each.value.peer_region
  auto_accept   = false  # Must be accepted in peer region

  tags = merge(
    var.tags,
    {
      Name        = each.key
      Environment = var.environment
      Type        = "cross-region"
      PeerRegion  = each.value.peer_region
      ManagedBy   = "terraform"
    }
  )
}

# Accept the peering connection in the peer region
resource "aws_vpc_peering_connection_accepter" "peer" {
  for_each = local.peer_connections
  
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.main[each.key].id
  auto_accept               = true

  tags = merge(
    var.tags,
    {
      Name        = "${each.key}-accepter"
      Environment = var.environment
      Type        = "cross-region"
      ManagedBy   = "terraform"
    }
  )
}

# Configure peering connection options
resource "aws_vpc_peering_connection_options" "requester" {
  for_each = local.peer_connections
  
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer[each.key].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  for_each = local.peer_connections
  
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer[each.key].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# Routes in the current VPC to peer VPCs
resource "aws_route" "to_peer" {
  for_each = { for pair in setproduct(keys(local.peer_connections), var.route_table_ids) : 
    "${pair[0]}-${pair[1]}" => {
      peer_key = pair[0]
      route_table_id = pair[1]
    }
  }
  
  route_table_id            = each.value.route_table_id
  destination_cidr_block    = local.peer_connections[each.value.peer_key].peer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main[each.value.peer_key].id
  
  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

# Routes in peer VPCs back to current VPC
resource "aws_route" "from_peer" {
  for_each = { for pair in setproduct(keys(local.peer_connections), 
    flatten([for p in var.peer_configs : p.route_table_ids])) : 
    "${pair[0]}-${pair[1]}" => {
      peer_key = pair[0]
      route_table_id = pair[1]
      peer_idx = index(keys(local.peer_connections), pair[0])
    } if contains(var.peer_configs[index(keys(local.peer_connections), pair[0])].route_table_ids, pair[1])
  }
  
  provider                  = aws.peer
  route_table_id            = each.value.route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main[each.value.peer_key].id
  
  depends_on = [aws_vpc_peering_connection_accepter.peer]
}
