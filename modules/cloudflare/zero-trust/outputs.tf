# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "tunnel_cname" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.cname
}

output "tunnel_token" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
}