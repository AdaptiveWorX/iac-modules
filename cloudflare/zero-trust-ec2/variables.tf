# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string

  validation {
    condition     = length(trim(var.cloudflare_account_id)) > 0
    error_message = "Provide a non-empty Cloudflare account ID."
  }
}

variable "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare DNS zone ID"
  type        = string

  validation {
    condition     = length(trim(var.cloudflare_zone_id)) > 0
    error_message = "Provide a non-empty Cloudflare zone ID."
  }
}

variable "dns_hostname" {
  description = "DNS hostname for the tunnel"
  type        = string
  default     = ""
}

variable "create_dns_record" {
  description = "Whether to create DNS CNAME record for the tunnel"
  type        = bool
  default     = true
}

variable "create_wildcard_record" {
  description = "Whether to create wildcard DNS record"
  type        = bool
  default     = false
}

variable "enable_warp_routing" {
  description = "Enable WARP routing for the tunnel"
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "List of ingress rules for the tunnel"
  type = list(object({
    hostname = optional(string)
    path     = optional(string)
    service  = string
    origin_request = optional(object({
      connect_timeout          = optional(string)
      tls_timeout              = optional(string)
      tcp_keep_alive           = optional(string)
      no_happy_eyeballs        = optional(bool)
      keep_alive_connections   = optional(number)
      keep_alive_timeout       = optional(string)
      http_host_header         = optional(string)
      origin_server_name       = optional(string)
      ca_pool                  = optional(string)
      no_tls_verify            = optional(bool)
      disable_chunked_encoding = optional(bool)
      proxy_address            = optional(string)
      proxy_port               = optional(number)
      proxy_type               = optional(string)
    }))
  }))
  default = [
    {
      service = "http_status:404"
    }
  ]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for SSM parameter storage"
  type        = string
  default     = "us-east-1"
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting SSM parameters"
  type        = string
  default     = ""
}

variable "ssm_parameter_prefix" {
  description = "Prefix for SSM parameter names"
  type        = string
  default     = "/cloudflare/tunnel"
}

variable "enable_route_detection" {
  description = "Enable automatic route detection from regions.yaml"
  type        = bool
  default     = true
}

variable "regions_config_path" {
  description = "Path to regions.yaml configuration file"
  type        = string
  default     = ""
}

variable "static_routes" {
  description = "Static route configurations (used when route detection is disabled)"
  type = list(object({
    network = string
    comment = string
  }))
  default = []
}

variable "tunnel_config" {
  description = "Additional tunnel configuration options"
  type = object({
    protocol                 = optional(string, "quic")
    loglevel                 = optional(string, "info")
    transport_protocol       = optional(string, "quic")
    no_tls_verify            = optional(bool, false)
    grace_period             = optional(string, "30s")
    metrics_update_frequency = optional(string, "5s")
  })
  default = {}
}

variable "notification_email" {
  description = "Email address for tunnel notifications"
  type        = string
  default     = ""
}
