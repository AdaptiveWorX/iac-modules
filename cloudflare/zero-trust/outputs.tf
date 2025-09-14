# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "tunnel_id" {
  description = "The ID of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.name
}

output "tunnel_token" {
  description = "The token for the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.tunnel_token
  sensitive   = true
}

output "tunnel_cname" {
  description = "The CNAME record for the tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "tunnel_routes" {
  description = "Configured VPC routes for the tunnel"
  value = {
    for key, route in cloudflare_zero_trust_tunnel_cloudflared_route.vpc_routes : 
    key => {
      network = route.network
      comment = route.comment
    }
  }
}

output "dns_record" {
  description = "DNS record details for the tunnel"
  value = var.create_dns_record ? {
    fqdn    = local.dns_fqdn
    name    = local.dns_subdomain
    zone_id = var.cloudflare_zone_id
    type    = "CNAME"
    value   = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  } : null
}

output "access_application_id" {
  description = "The ID of the Cloudflare Access application"
  value       = var.create_access_application ? cloudflare_zero_trust_access_application.main[0].id : null
}

output "access_application_domain" {
  description = "The domain of the Cloudflare Access application"
  value       = var.create_access_application ? cloudflare_zero_trust_access_application.main[0].domain : null
}

output "ssm_parameters" {
  description = "SSM parameter paths for tunnel configuration"
  value = {
    token  = aws_ssm_parameter.tunnel_token.name
    id     = aws_ssm_parameter.tunnel_id.name
    config = aws_ssm_parameter.tunnel_config.name
  }
}

output "ssm_parameter_arns" {
  description = "SSM parameter ARNs for IAM policies"
  value = {
    token  = aws_ssm_parameter.tunnel_token.arn
    id     = aws_ssm_parameter.tunnel_id.arn
    config = aws_ssm_parameter.tunnel_config.arn
  }
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for tunnel metrics"
  value = {
    name = aws_cloudwatch_log_group.tunnel.name
    arn  = aws_cloudwatch_log_group.tunnel.arn
  }
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard for tunnel monitoring"
  value       = var.create_dashboard ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.tunnel[0].dashboard_name}" : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for tunnel alerts"
  value       = var.create_alerts ? aws_sns_topic.tunnel_alerts[0].arn : null
}

output "tunnel_configuration" {
  description = "Complete tunnel configuration for reference"
  value = {
    tunnel_id     = cloudflare_zero_trust_tunnel_cloudflared.main.id
    tunnel_name   = local.tunnel_name
    account_id    = var.cloudflare_account_id
    environment   = var.environment
    dns_fqdn      = local.dns_fqdn
    dns_subdomain = local.dns_subdomain
    enabled_routes = length(cloudflare_zero_trust_tunnel_cloudflared_route.vpc_routes)
    warp_routing  = var.enable_warp_routing
  }
}

output "webhook_url" {
  description = "Webhook URL for health checks"
  value       = local.webhook_url
}

output "deployment_region" {
  description = "AWS region where tunnel resources are deployed"
  value       = data.aws_region.current.name
}

output "deployment_account" {
  description = "AWS account ID where tunnel resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "module_version" {
  description = "Version of the zero-trust-simplified module"
  value       = "1.0.0"
}
