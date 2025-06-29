# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">4.0.0"
    }
  }
}

# Create the Cloudflare Zero Trust Tunnel
resource "random_password" "tunnel_secret" {
  length = 64
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = "${var.prefix}-cf-tunnel"
  secret     = base64encode(random_password.tunnel_secret.result)
}

# Create Cloudflare Tunnel Routes from a list
resource "cloudflare_zero_trust_tunnel_route" "routes" {
  for_each   = zipmap([for i, route in var.routes : i], var.routes)
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = each.value.network
  comment    = "Tunnel route for ${each.value.comment}"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  config {
    warp_routing {
      enabled = true
    }
    dynamic "ingress_rule" {
      for_each = var.ingress_rules
      content {
        hostname = ingress_rule.value.hostname
        path     = ingress_rule.value.path
        service  = ingress_rule.value.service
      }
    }
  }
}