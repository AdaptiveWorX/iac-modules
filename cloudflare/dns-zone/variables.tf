# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "cloudflare_api_token" {
  description = "Cloudflare API token for authentication"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  type        = string
}

variable "zone_name" {
  description = "The DNS zone name (e.g., example.com)"
  type        = string
}

variable "import_zone_id" {
  description = "Zone ID for importing existing zones. Leave empty to create new zone"
  type        = string
  default     = ""
}

variable "plan_type" {
  description = "The Cloudflare plan type (free, pro, business, enterprise)"
  type        = string
  default     = "free"
  
  validation {
    condition     = contains(["free", "pro", "business", "enterprise"], var.plan_type)
    error_message = "Plan type must be one of: free, pro, business, enterprise"
  }
}

variable "zone_type" {
  description = "Zone type (full or partial)"
  type        = string
  default     = "full"
  
  validation {
    condition     = contains(["full", "partial"], var.zone_type)
    error_message = "Zone type must be either 'full' or 'partial'"
  }
}

variable "paused" {
  description = "Whether this zone is paused"
  type        = bool
  default     = false
}

variable "jump_start" {
  description = "Whether to scan for DNS records on creation"
  type        = bool
  default     = false
}

variable "manage_zone_settings" {
  description = "Whether to manage zone settings"
  type        = bool
  default     = true
}

variable "zone_settings" {
  description = "Map of zone settings to configure"
  type        = map(any)
  default     = {}
}

variable "enable_dnssec" {
  description = "Whether to enable DNSSEC for the zone"
  type        = bool
  default     = false
}

variable "allow_overwrite" {
  description = "Allow overwriting existing DNS records"
  type        = bool
  default     = false
}

# DNS Records Variables

variable "a_records" {
  description = "Map of A records to create"
  type = map(object({
    value   = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
    comment = optional(string)
  }))
  default = {}
}

variable "aaaa_records" {
  description = "Map of AAAA records to create"
  type = map(object({
    value   = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
    comment = optional(string)
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME records to create"
  type = map(object({
    value   = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
    comment = optional(string)
  }))
  default = {}
}

variable "mx_records" {
  description = "Map of MX records to create (critical for email)"
  type = map(object({
    name     = optional(string)
    value    = string
    priority = number
    ttl      = optional(number, 1)
    comment  = optional(string)
  }))
  default = {}
}

variable "txt_records" {
  description = "Map of TXT records to create (includes SPF, DKIM, DMARC)"
  type = map(object({
    name    = optional(string)
    value   = string
    ttl     = optional(number, 1)
    comment = optional(string)
  }))
  default = {}
}

variable "caa_records" {
  description = "Map of CAA records to create"
  type = map(object({
    flags   = number
    tag     = string
    value   = string
    ttl     = optional(number, 1)
    comment = optional(string)
  }))
  default = {}
}

variable "srv_records" {
  description = "Map of SRV records to create"
  type = map(object({
    service  = string
    proto    = string
    name     = string
    priority = number
    weight   = number
    port     = number
    target   = string
    ttl      = optional(number, 1)
    comment  = optional(string)
  }))
  default = {}
}

variable "ns_records" {
  description = "Map of NS records to create (for subdomains)"
  type = map(object({
    value   = string
    ttl     = optional(number, 1)
    comment = optional(string)
  }))
  default = {}
}

# Page Rules and Firewall

variable "page_rules" {
  description = "Map of page rules to create"
  type = map(object({
    target   = string
    priority = optional(number, 1)
    status   = optional(string, "active")
    actions  = map(any)
  }))
  default = {}
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    action      = string
    expression  = string
    description = string
    enabled     = optional(bool, true)
  }))
  default = []
}

# Tags

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
