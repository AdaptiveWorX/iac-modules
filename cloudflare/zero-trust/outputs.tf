# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "tunnel_name" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "tunnel_secret" {
  value     = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_secret
  sensitive = true
}
