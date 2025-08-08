# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "tunnel_id" {
  description = "The ID of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "tunnel_token" {
  description = "The tunnel token for cloudflared"
  value       = cloudflare_zero_trust_tunnel_cloudflared_token.token.token
  sensitive   = true
}

output "tunnel_token_ssm_parameter" {
  description = "The SSM parameter name containing the tunnel token"
  value       = var.store_token_in_ssm ? aws_ssm_parameter.tunnel_token[0].name : null
}

output "tunnel_token_ssm_arn" {
  description = "The SSM parameter ARN containing the tunnel token"
  value       = var.store_token_in_ssm ? aws_ssm_parameter.tunnel_token[0].arn : null
}

output "tunnel_routes" {
  description = "Map of configured tunnel routes"
  value = {
    for idx, route in cloudflare_zero_trust_tunnel_route.vpc_routes : 
    route.network => route.comment
  }
}

output "access_application_id" {
  description = "The ID of the Zero Trust Access application"
  value       = var.create_access_application ? cloudflare_zero_trust_access_application.app[0].id : null
}

output "tunnel_cname" {
  description = "The CNAME record for the tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}