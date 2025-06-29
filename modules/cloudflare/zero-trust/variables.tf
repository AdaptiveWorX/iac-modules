# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "cloudflare_account_id" {
  description = "The account ID in Cloudflare."
  type        = string
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
