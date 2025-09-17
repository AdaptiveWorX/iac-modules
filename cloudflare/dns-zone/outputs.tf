# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "zone_id" {
  description = "The zone ID"
  value       = local.zone_id
}

output "zone_name" {
  description = "The zone name"
  value       = local.zone_name
}

output "name_servers" {
  description = "Cloudflare-assigned name servers for the zone"
  value = data.cloudflare_zone.zone[0].name_servers
}

output "status" {
  description = "Status of the zone"
  value = data.cloudflare_zone.zone[0].status
}

output "dnssec_status" {
  description = "DNSSEC status if enabled"
  value = var.enable_dnssec ? cloudflare_zone_dnssec.dnssec[0].status : null
}

# Record outputs for validation
output "a_records" {
  description = "Created A records"
  value = {
    for name, record in cloudflare_dns_record.a_records : 
    name => {
      id      = record.id
      name    = record.name
      content = record.content
      proxied = record.proxied
    }
  }
}

output "mx_records" {
  description = "Created MX records (critical for email)"
  value = {
    for name, record in cloudflare_dns_record.mx_records : 
    name => {
      id       = record.id
      name     = record.name
      content  = record.content
      priority = record.priority
    }
  }
  sensitive = false
}

output "txt_records" {
  description = "Created TXT records (includes SPF, DKIM, DMARC)"
  value = {
    for name, record in cloudflare_dns_record.txt_records : 
    name => {
      id      = record.id
      name    = record.name
      content = record.content
    }
  }
}

output "cname_records" {
  description = "Created CNAME records"
  value = {
    for name, record in cloudflare_dns_record.cname_records : 
    name => {
      id      = record.id
      name    = record.name
      content = record.content
      proxied = record.proxied
    }
  }
}

output "page_rules" {
  description = "Created page rules"
  value = {
    for name, rule in cloudflare_page_rule.rules : 
    name => {
      id       = rule.id
      target   = rule.target
      priority = rule.priority
      status   = rule.status
    }
  }
}

# Firewall rules commented out as they're replaced with rulesets in v5
# output "firewall_rules" {
#   description = "Created firewall rules"
#   value = {}
# }
