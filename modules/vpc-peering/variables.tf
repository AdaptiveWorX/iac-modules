# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "environment" {
  description = "Environment name (e.g., sdlc, stage, prod)"
  type        = string
}

variable "current_region" {
  description = "Current AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in the current region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC in the current region"
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs in the current VPC to add peering routes"
  type        = list(string)
}

variable "peer_configs" {
  description = "List of peer VPC configurations"
  type = list(object({
    region          = string
    vpc_id          = string
    vpc_cidr        = string
    route_table_ids = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
