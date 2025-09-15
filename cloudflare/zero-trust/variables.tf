# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "cloudflare_account_id" {
  description = "The account ID in Cloudflare."
  type        = string

  validation {
    condition     = length(trim(var.cloudflare_account_id)) > 0
    error_message = "Provide a non-empty Cloudflare account ID."
  }
}

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "organization" {
  description = "Terraform Cloud organization name."
  type        = string
}

variable "routes" {
  description = "List of routes for the Cloudflare Tunnel."
  type = list(object({
    network = string
    comment = string
  }))
}

variable "ingress_rules" {
  description = "List of ingress rules for the Cloudflare Tunnel."
  type = list(object({
    hostname = optional(string)
    path     = optional(string)
    service  = string
  }))
}

variable "tunnel_secret" {
  description = "Secret for the Cloudflare Tunnel. If not provided, a random one will be generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "config_src" {
  description = "Indicates if this is a locally or remotely configured tunnel. Valid values: 'local', 'cloudflare'."
  type        = string
  default     = "cloudflare"

  validation {
    condition     = contains(["local", "cloudflare"], var.config_src)
    error_message = "The config_src must be either 'local' or 'cloudflare'."
  }
}

variable "manage_routes" {
  description = "Map of network routes to boolean values indicating whether this tunnel should manage the route. Used to prevent duplicate route creation across multiple tunnels."
  type        = map(bool)
  default     = {}
}
