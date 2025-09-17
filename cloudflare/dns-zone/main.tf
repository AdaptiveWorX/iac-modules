# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

# Provider configuration is handled by Terragrunt, not the module
# For imported zones, we just use a data source - no need to create
data "cloudflare_zone" "zone" {
  count = var.import_zone_id != "" ? 1 : 0
  
  zone_id = var.import_zone_id
}

locals {
  # For importing existing zones, use the zone_id directly
  # This avoids the index reference issue when data source doesn't exist
  zone_id = var.import_zone_id != "" ? var.import_zone_id : ""
  zone_name = var.zone_name
}

# Zone settings management - Using individual cloudflare_zone_setting resources
resource "cloudflare_zone_setting" "ssl" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "ssl"
  value      = lookup(var.zone_settings, "ssl", "flexible")
}

resource "cloudflare_zone_setting" "always_use_https" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "always_use_https"
  value      = lookup(var.zone_settings, "always_use_https", "on")
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "automatic_https_rewrites"
  value      = lookup(var.zone_settings, "automatic_https_rewrites", "on")
}

resource "cloudflare_zone_setting" "min_tls_version" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "min_tls_version"
  value      = lookup(var.zone_settings, "min_tls_version", "1.2")
}

resource "cloudflare_zone_setting" "security_level" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "security_level"
  value      = lookup(var.zone_settings, "security_level", "medium")
}

resource "cloudflare_zone_setting" "challenge_ttl" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "challenge_ttl"
  value      = lookup(var.zone_settings, "challenge_ttl", 1800)
}

# Browser Cache TTL - Commented out as it requires specific values for free plans
# resource "cloudflare_zone_setting" "browser_cache_ttl" {
#   count = var.manage_zone_settings ? 1 : 0
#   
#   zone_id    = local.zone_id
#   setting_id = "browser_cache_ttl"
#   value      = lookup(var.zone_settings, "browser_cache_ttl", 14400)
# }

resource "cloudflare_zone_setting" "cache_level" {
  count = var.manage_zone_settings ? 1 : 0
  
  zone_id    = local.zone_id
  setting_id = "cache_level"
  value      = lookup(var.zone_settings, "cache_level", "standard")
}

# DNSSEC management
resource "cloudflare_zone_dnssec" "dnssec" {
  count = var.enable_dnssec ? 1 : 0
  
  zone_id = local.zone_id
}

# A Records - Changed from cloudflare_record to cloudflare_dns_record
resource "cloudflare_dns_record" "a_records" {
  for_each = var.a_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "A"
  content = each.value.value  # Changed from value to content
  ttl     = lookup(each.value, "ttl", 1)
  proxied = lookup(each.value, "proxied", false)
  comment = lookup(each.value, "comment", null)
}

# AAAA Records
resource "cloudflare_dns_record" "aaaa_records" {
  for_each = var.aaaa_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "AAAA"
  content = each.value.value
  ttl     = lookup(each.value, "ttl", 1)
  proxied = lookup(each.value, "proxied", false)
  comment = lookup(each.value, "comment", null)
}

# CNAME Records
resource "cloudflare_dns_record" "cname_records" {
  for_each = var.cname_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = each.value.value
  ttl     = lookup(each.value, "ttl", 1)
  proxied = lookup(each.value, "proxied", false)
  comment = lookup(each.value, "comment", null)
}

# MX Records (Critical for email)
resource "cloudflare_dns_record" "mx_records" {
  for_each = var.mx_records
  
  zone_id  = local.zone_id
  # Keep @ as-is for root domain - Cloudflare provider handles @ correctly
  name     = lookup(each.value, "name", "@")
  type     = "MX"
  content  = each.value.value
  priority = each.value.priority
  ttl      = lookup(each.value, "ttl", 1)
  comment  = lookup(each.value, "comment", null)
}

# TXT Records (Including SPF, DMARC, DKIM)
resource "cloudflare_dns_record" "txt_records" {
  for_each = var.txt_records
  
  zone_id = local.zone_id
  # Keep @ as-is for root domain - Cloudflare provider handles @ correctly
  # If name field exists, use it; otherwise use the key
  name    = contains(keys(each.value), "name") ? each.value.name : each.key
  type    = "TXT"
  content = each.value.value
  ttl     = lookup(each.value, "ttl", 1)
  comment = lookup(each.value, "comment", null)
}

# CAA Records  
resource "cloudflare_dns_record" "caa_records" {
  for_each = var.caa_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "CAA"
  ttl     = lookup(each.value, "ttl", 1)
  comment = lookup(each.value, "comment", null)
  
  data = {
    flags = each.value.flags
    tag   = each.value.tag
    value = each.value.value
  }
}

# SRV Records
resource "cloudflare_dns_record" "srv_records" {
  for_each = var.srv_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "SRV"
  ttl     = lookup(each.value, "ttl", 1)
  comment = lookup(each.value, "comment", null)
  
  data = {
    service  = each.value.service
    proto    = each.value.proto
    name     = each.value.name
    priority = each.value.priority
    weight   = each.value.weight
    port     = each.value.port
    target   = each.value.target
  }
}

# NS Records (for subdomains)
resource "cloudflare_dns_record" "ns_records" {
  for_each = var.ns_records
  
  zone_id = local.zone_id
  name    = each.key
  type    = "NS"
  content = each.value.value
  ttl     = lookup(each.value, "ttl", 1)
  comment = lookup(each.value, "comment", null)
}

# Page Rules  
resource "cloudflare_page_rule" "rules" {
  for_each = var.page_rules
  
  zone_id  = local.zone_id
  target   = each.value.target
  priority = lookup(each.value, "priority", 1)
  status   = lookup(each.value, "status", "active")
  
  # Direct actions mapping
  actions = each.value.actions
}

# Firewall Rules - These have been replaced in v5 with rulesets
# Commenting out for now as we focus on DNS migration
# resource "cloudflare_filter" "firewall_filters" {
#   for_each = { for idx, rule in var.firewall_rules : idx => rule }
#   
#   zone_id     = local.zone_id
#   expression  = each.value.expression
#   description = each.value.description
# }
# 
# resource "cloudflare_firewall_rule" "firewall_rules" {
#   for_each = { for idx, rule in var.firewall_rules : idx => rule }
#   
#   zone_id     = local.zone_id
#   filter      = cloudflare_filter.firewall_filters[each.key].id
#   action      = each.value.action
#   description = each.value.description
# }
