# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

locals {
  tunnel_secret_raw = random_password.tunnel_secret.result
  tunnel_secret_b64 = base64encode(local.tunnel_secret_raw)
  
  ssm_prefix_trimmed = trimsuffix(var.ssm_parameter_prefix, "/")
  ssm_environment_path = "${local.ssm_prefix_trimmed}/${var.environment}"
}

# Create Cloudflare Zero Trust tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  config_src    = "cloudflare"
  tunnel_secret = local.tunnel_secret_b64
  
  lifecycle {
    # This allows updating the tunnel without destroying and recreating it
    create_before_destroy = true
  }
}

# Create dynamic tunnel routes and ingress configuration
locals {
  # Read regions configuration if path is provided
  regions_config = var.regions_config_path != "" ? yamldecode(file(var.regions_config_path)) : {}

  # Get enabled regions for the environment
  enabled_regions = try(
    local.regions_config.environments[var.environment].enabled_regions,
    []
  )

  # Build dynamic routes when detection is enabled
  dynamic_routes = var.enable_route_detection ? [
    for region in local.enabled_regions : {
      network = try(local.regions_config.cidr_allocations[var.environment][region], null)
      comment = "Auto-configured route for ${var.environment} (${region})"
    }
    if try(local.regions_config.cidr_allocations[var.environment][region], null) != null
  ] : []

  # Static routes supplied via variables (used when detection is disabled or yields no results)
  static_routes = [
    for route in var.static_routes : {
      network = route.network
      comment = route.comment
    }
  ]

  tunnel_routes = {
    for route in concat(local.dynamic_routes, local.static_routes) : route.network => route
    if route.network != null
  }

  # Build ingress configuration and ensure catch-all 404 rule
  ingress_rules = concat(
    [
      for rule in var.ingress_rules : merge(
        {
          service = rule.service
        },
        rule.hostname != null ? { hostname = rule.hostname } : {},
        rule.path != null ? { path = rule.path } : {},
        rule.origin_request != null ? {
          origin_request = {
            for key, value in rule.origin_request : key => value
            if value != null
          }
        } : {}
      ) if rule.service != "http_status:404"
    ],
    [
      {
        service = "http_status:404"
      }
    ]
  )

  # Filter tunnel configuration into a compact map for Cloudflare
  filtered_tunnel_config = {
    for key, value in var.tunnel_config : key => value
    if value != null
  }
}

# Create tunnel routes
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "routes" {
  for_each = local.tunnel_routes
  
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = each.value.network
  comment    = each.value.comment
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config = merge({
    ingress = local.ingress_rules,
    warp_routing = {
      enabled = var.enable_warp_routing
    }
  }, local.filtered_tunnel_config)

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [
      source
    ]
  }
}

# Store tunnel token in AWS SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_token" {
  name        = "${local.ssm_environment_path}/token"
  description = "Cloudflare tunnel token for ${var.environment}"
  type        = "SecureString"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
  overwrite   = true
  key_id      = var.kms_key_id != "" ? var.kms_key_id : null
  
  tags = merge(var.tags, {
    Name        = "${var.environment}-cf-tunnel-token"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Store tunnel credentials in AWS SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_credentials" {
  name        = "${local.ssm_environment_path}/credentials"
  description = "Cloudflare tunnel credentials JSON for ${var.environment}"
  type        = "SecureString"
  value = jsonencode({
    AccountTag   = var.cloudflare_account_id
    TunnelSecret = local.tunnel_secret_b64
    TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
    TunnelName   = var.tunnel_name
  })
  overwrite = true
  key_id    = var.kms_key_id != "" ? var.kms_key_id : null
  
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
