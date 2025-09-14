# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

# Create the Cloudflare Zero Trust Tunnel
resource "random_password" "tunnel_secret" {
  length = 64
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = "${var.prefix}-cf-tunnel"
  config_src    = var.config_src
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
  
  lifecycle {
    # This allows updating the tunnel without destroying and recreating it
    create_before_destroy = true
  }
}

# Create Cloudflare Tunnel Routes from a list
# Only create routes where manage_routes[network] is true (or not specified, defaulting to true)
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "routes" {
  for_each = {
    for i, route in var.routes : route.network => route
    if lookup(var.manage_routes, route.network, true)
  }
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = each.key
  comment    = "Tunnel route for ${each.value.comment}"

  # Manage route creation separately from the module by using lifecycle ignore_changes blocks
  lifecycle {
    ignore_changes = [
      # Ignore changes to virtual_network_id to prevent conflicts
      virtual_network_id,
    ]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  config = {
    # Create ingress rules from the provided list and add catch-all rule
    ingress = concat(
      [
        for rule in var.ingress_rules : {
          hostname = rule.hostname != null ? rule.hostname : null
          path     = rule.path != null ? rule.path : null
          service  = rule.service
        } if rule.service != "http_status:404"
      ],
      [{
        service = "http_status:404"
      }]
    )
  }

  lifecycle {
    create_before_destroy = true
    # This resource can't be destroyed via Terraform
    prevent_destroy = false
    # Ignore changes to computed fields that Cloudflare manages
    ignore_changes = [
      config,
      source
    ]
  }
}
