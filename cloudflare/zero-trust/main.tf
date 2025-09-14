# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"   # Latest 3.x version as of Sep 2025
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Local variables for dynamic configuration
locals {
  tunnel_name = "${var.name_prefix}-${var.environment}-tunnel"
  
  # Parse tunnel routes from input
  tunnel_routes = [
    for route in var.vpc_routes : {
      network = route.cidr
      comment = "${route.description} - ${route.region}"
      enabled = route.enabled
    }
  ]
  
  # DNS configuration
  dns_subdomain = var.environment == "prod" ? "tunnel" : "tunnel-${var.environment}"
  dns_fqdn      = "${local.dns_subdomain}.${var.dns_zone}"
  
  # Tags for resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "CloudflareZeroTrust"
      Module      = "zero-trust-simplified"
    }
  )
}

# Create Cloudflare tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.cloudflare_account_id
  name       = local.tunnel_name
  # Note: Secret is managed separately through tunnel token
}

# Generate random secret for tunnel
resource "random_password" "tunnel_secret" {
  length  = 32
  special = false
}

# Create tunnel routes for VPC access
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "vpc_routes" {
  for_each = {
    for idx, route in local.tunnel_routes : 
    "${var.environment}-${idx}" => route if route.enabled
  }
  
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  network    = each.value.network
  comment    = each.value.comment
}

# DNS record for tunnel
resource "cloudflare_dns_record" "tunnel" {
  count = var.create_dns_record ? 1 : 0
  
  zone_id = var.cloudflare_zone_id
  name    = local.dns_subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1  # Automatic TTL when proxied
  proxied = true
  comment = "Cloudflare Zero Trust tunnel for ${var.environment} environment"
}

# Store tunnel token in AWS SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_token" {
  name  = "/${var.environment}/cloudflare/tunnel/token"
  type  = "SecureString"
  value = cloudflare_zero_trust_tunnel_cloudflared.main.tunnel_token
  
  description = "Cloudflare tunnel token for ${var.environment} environment"
  
  tags = local.common_tags
}

# Store tunnel ID for reference
resource "aws_ssm_parameter" "tunnel_id" {
  name  = "/${var.environment}/cloudflare/tunnel/id"
  type  = "String"
  value = cloudflare_zero_trust_tunnel_cloudflared.main.id
  
  description = "Cloudflare tunnel ID for ${var.environment} environment"
  
  tags = local.common_tags
}

# Store tunnel configuration
resource "aws_ssm_parameter" "tunnel_config" {
  name  = "/${var.environment}/cloudflare/tunnel/config"
  type  = "String"
  value = jsonencode({
    tunnel_id    = cloudflare_zero_trust_tunnel_cloudflared.main.id
    tunnel_name  = local.tunnel_name
    account_id   = var.cloudflare_account_id
    dns_fqdn     = local.dns_fqdn
    environment  = var.environment
    routes       = local.tunnel_routes
    created_at   = timestamp()
  })
  
  description = "Cloudflare tunnel configuration for ${var.environment} environment"
  
  tags = local.common_tags
}

# Create Access Application (if enabled)
resource "cloudflare_zero_trust_access_application" "main" {
  count = var.create_access_application ? 1 : 0
  
  zone_id                   = var.cloudflare_zone_id
  name                      = "${var.environment} Tunnel Access"
  domain                    = var.access_domain != "" ? var.access_domain : local.dns_fqdn
  type                      = "self_hosted"
  session_duration          = var.session_duration
  auto_redirect_to_identity = true
  
  # App launcher settings
  app_launcher_visible = true
}

# Configure tunnel with WARP routing (simplified - config happens in cloudflared)
# The actual tunnel configuration is handled by the cloudflared instance
# using the token stored in SSM Parameter Store

# Create CloudWatch log group for tunnel metrics
resource "aws_cloudwatch_log_group" "tunnel" {
  name              = "/cloudflare/tunnel/${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = local.common_tags
}

# Create CloudWatch dashboard for monitoring
resource "aws_cloudwatch_dashboard" "tunnel" {
  count = var.create_dashboard ? 1 : 0
  
  dashboard_name = "${var.environment}-cloudflare-tunnel"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["CloudflareTunnel", "TunnelStatus", { stat = "Average", label = "Tunnel Status" }],
            [".", "ActiveConnections", { stat = "Sum", label = "Active Connections" }],
            [".", "TunnelRegistered", { stat = "Average", label = "Registration Status" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Tunnel Health Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Usage" }],
            [".", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 Instance Metrics"
        }
      }
    ]
  })
}

# Create SNS topic for alerts
resource "aws_sns_topic" "tunnel_alerts" {
  count = var.create_alerts ? 1 : 0
  
  name = "${var.environment}-cloudflare-tunnel-alerts"
  
  tags = local.common_tags
}

# Create SNS topic subscription
resource "aws_sns_topic_subscription" "tunnel_alerts_email" {
  count = var.create_alerts && length(var.alert_emails) > 0 ? length(var.alert_emails) : 0
  
  topic_arn = aws_sns_topic.tunnel_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# Output tunnel webhook URL for health checks
locals {
  webhook_url = var.create_webhook ? "https://${local.dns_fqdn}/health" : null
}
