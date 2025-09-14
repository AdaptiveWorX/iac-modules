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

output "tunnel_cname" {
  description = "The CNAME value for the tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}

output "tunnel_token" {
  description = "The tunnel token (sensitive)"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
  sensitive   = true
}

output "tunnel_secret" {
  description = "The tunnel secret (sensitive)"
  value       = random_password.tunnel_secret.result
  sensitive   = true
}

output "ssm_token_parameter_name" {
  description = "The name of the SSM parameter containing the tunnel token"
  value       = aws_ssm_parameter.tunnel_token.name
}

output "ssm_token_parameter_arn" {
  description = "The ARN of the SSM parameter containing the tunnel token"
  value       = aws_ssm_parameter.tunnel_token.arn
}

output "ssm_credentials_parameter_name" {
  description = "The name of the SSM parameter containing the tunnel credentials"
  value       = aws_ssm_parameter.tunnel_credentials.name
}

output "ssm_credentials_parameter_arn" {
  description = "The ARN of the SSM parameter containing the tunnel credentials"
  value       = aws_ssm_parameter.tunnel_credentials.arn
}

output "dns_record_name" {
  description = "The DNS record name for the tunnel"
  value       = var.create_dns_record ? cloudflare_record.tunnel_dns[0].name : ""
}

output "dns_record_value" {
  description = "The DNS record value for the tunnel"
  value       = var.create_dns_record ? cloudflare_record.tunnel_dns[0].value : ""
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  value       = var.cloudflare_account_id
}

output "ingress_rules" {
  description = "The configured ingress rules"
  value       = var.ingress_rules
}

output "enable_warp_routing" {
  description = "Whether WARP routing is enabled"
  value       = var.enable_warp_routing
}

output "tunnel_config" {
  description = "The tunnel configuration"
  value       = var.tunnel_config
}
