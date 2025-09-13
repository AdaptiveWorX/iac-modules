# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Create the Cloudflare Zero Trust Tunnel
resource "random_password" "tunnel_secret" {
  length = 64
  special = true
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = base64encode(random_password.tunnel_secret.result)
}

# Create tunnel token for cloudflared authentication
resource "cloudflare_zero_trust_tunnel_cloudflared_token" "token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

# Create Cloudflare Tunnel Routes for VPC CIDR blocks
resource "cloudflare_zero_trust_tunnel_route" "vpc_routes" {
  for_each   = { for idx, route in var.vpc_routes : idx => route }
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = each.value.cidr
  comment    = each.value.description
}

# Configure tunnel with WARP routing enabled
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  
  config {
    warp_routing {
      enabled = true
    }
    
    # Default catch-all rule for WARP traffic
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Store tunnel token in AWS SSM Parameter Store for ECS tasks
resource "aws_ssm_parameter" "tunnel_token" {
  count = var.store_token_in_ssm ? 1 : 0
  
  name        = "/${var.environment}/cloudflare/tunnel/${var.tunnel_name}/token"
  description = "Cloudflare tunnel token for ${var.tunnel_name}"
  type        = "SecureString"
  value       = cloudflare_zero_trust_tunnel_cloudflared_token.token.token
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.tunnel_name}-token"
      Environment = var.environment
      Purpose     = "cloudflare-tunnel"
    }
  )
}

# Create Zero Trust Access Application (optional)
resource "cloudflare_zero_trust_access_application" "app" {
  count = var.create_access_application ? 1 : 0
  
  zone_id                   = var.cloudflare_zone_id
  name                      = "${var.tunnel_name}-access"
  domain                    = var.access_domain
  session_duration          = var.session_duration
  auto_redirect_to_identity = true
  
  type = "self_hosted"
}