# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Generate tunnel secret
resource "random_password" "tunnel_secret" {
  length  = 32
  special = true
}

# Create Cloudflare Zero Trust tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  config_src    = "cloudflare"
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
  
  lifecycle {
    # This allows updating the tunnel without destroying and recreating it
    create_before_destroy = true
  }
}

# Create dynamic tunnel routes based on regions.yaml
locals {
  # Read regions configuration if path is provided
  regions_config = var.regions_config_path != "" ? yamldecode(file(var.regions_config_path)) : {}
  
  # Get enabled regions for the environment
  enabled_regions = try(
    local.regions_config.environments[var.environment].enabled_regions,
    []
  )
  
  # Build CIDR list for all enabled regions
  enabled_cidrs = var.enable_route_detection ? [
    for region in local.enabled_regions :
    try(local.regions_config.cidr_allocations[var.environment][region], null)
    if try(local.regions_config.cidr_allocations[var.environment][region], null) != null
  ] : var.static_routes
  
  # Create route configurations
  tunnel_routes = [
    for cidr in local.enabled_cidrs : {
      network = cidr
      comment = "Auto-configured route for ${var.environment}"
    }
  ]
}

# Create tunnel routes
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "routes" {
  for_each = { for r in local.tunnel_routes : r.network => r }
  
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = each.key
  comment    = each.value.comment
}

# Store tunnel token in AWS SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_token" {
  name        = "/${var.environment}/cloudflare/tunnel/token"
  description = "Cloudflare tunnel token for ${var.environment}"
  type        = "SecureString"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
  
  tags = merge(var.tags, {
    Name        = "${var.environment}-cf-tunnel-token"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Store tunnel credentials in AWS SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_credentials" {
  name        = "/${var.environment}/cloudflare/tunnel/credentials"
  description = "Cloudflare tunnel credentials JSON for ${var.environment}"
  type        = "SecureString"
  value = jsonencode({
    AccountTag   = var.cloudflare_account_id
    TunnelSecret = base64encode(random_password.tunnel_secret.result)
    TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
    TunnelName   = var.tunnel_name
  })
  
  tags = merge(var.tags, {
    Name        = "${var.environment}-cf-tunnel-credentials"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Create DNS CNAME record for the tunnel
resource "cloudflare_record" "tunnel_dns" {
  count = var.create_dns_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.dns_hostname != "" ? var.dns_hostname : var.environment
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  comment = "Cloudflare tunnel for ${var.environment}"
}

# Create wildcard DNS record if needed
resource "cloudflare_record" "tunnel_dns_wildcard" {
  count = var.create_wildcard_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "*.${var.dns_hostname != "" ? var.dns_hostname : var.environment}"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  comment = "Wildcard Cloudflare tunnel for ${var.environment}"
}
