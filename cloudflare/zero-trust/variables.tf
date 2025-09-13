# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 30
    error_message = "Name prefix must be between 1 and 30 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{32}$", var.cloudflare_account_id))
    error_message = "Cloudflare account ID must be a 32-character hex string."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare DNS zone ID"
  type        = string
  default     = ""
  validation {
    condition     = var.cloudflare_zone_id == "" || can(regex("^[a-z0-9]{32}$", var.cloudflare_zone_id))
    error_message = "Cloudflare zone ID must be empty or a 32-character hex string."
  }
}

variable "dns_zone" {
  description = "DNS zone for tunnel endpoints (e.g., adaptiveworx.com)"
  type        = string
  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.dns_zone))
    error_message = "DNS zone must be a valid domain name."
  }
}

variable "vpc_routes" {
  description = "List of VPC routes to configure for the tunnel"
  type = list(object({
    cidr        = string
    region      = string
    description = string
    enabled     = bool
  }))
  default = []
  validation {
    condition = alltrue([
      for route in var.vpc_routes : can(cidrhost(route.cidr, 0))
    ])
    error_message = "All VPC routes must have valid CIDR blocks."
  }
}

variable "ingress_rules" {
  description = "Ingress rules for tunnel configuration"
  type = list(object({
    hostname = string
    path     = optional(string)
    service  = string
    origin_request = optional(object({
      connect_timeout          = optional(string)
      tls_timeout             = optional(string)
      tcp_keep_alive          = optional(string)
      no_happy_eyeballs       = optional(bool)
      keep_alive_connections  = optional(number)
      keep_alive_timeout      = optional(string)
      http_host_header        = optional(string)
      origin_server_name      = optional(string)
      ca_pool                 = optional(string)
      no_tls_verify           = optional(bool)
      disable_chunked_encoding = optional(bool)
      bastion_mode            = optional(bool)
      proxy_address           = optional(string)
      proxy_port              = optional(number)
      proxy_type              = optional(string)
    }))
  }))
  default = []
}

variable "create_dns_record" {
  description = "Create DNS record for tunnel endpoint"
  type        = bool
  default     = true
}

variable "create_access_application" {
  description = "Create Cloudflare Access application for tunnel"
  type        = bool
  default     = false
}

variable "create_access_groups" {
  description = "Create Cloudflare Access groups"
  type        = bool
  default     = false
}

variable "session_duration" {
  description = "Session duration for Access applications"
  type        = string
  default     = "24h"
  validation {
    condition     = can(regex("^[0-9]+[mhd]$", var.session_duration))
    error_message = "Session duration must be in format like 30m, 24h, or 7d."
  }
}

variable "allowed_identity_providers" {
  description = "List of allowed identity provider IDs"
  type        = list(string)
  default     = []
}

variable "google_workspace_domains" {
  description = "List of Google Workspace domains for authentication"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for domain in var.google_workspace_domains : can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", domain))
    ])
    error_message = "All Google Workspace domains must be valid domain names."
  }
}

variable "admin_emails" {
  description = "List of admin email addresses"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for email in var.admin_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All admin emails must be valid email addresses."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard for tunnel monitoring"
  type        = bool
  default     = true
}

variable "create_alerts" {
  description = "Create SNS alerts for tunnel monitoring"
  type        = bool
  default     = true
}

variable "alert_emails" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for email in var.alert_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All alert emails must be valid email addresses."
  }
}

variable "create_webhook" {
  description = "Create webhook endpoint for health checks"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}

variable "store_token_in_ssm" {
  description = "Store tunnel token in AWS SSM Parameter Store"
  type        = bool
  default     = true
}

variable "enable_warp_routing" {
  description = "Enable WARP routing for tunnel"
  type        = bool
  default     = true
}

variable "access_domain" {
  description = "Domain for Access application"
  type        = string
  default     = ""
}
