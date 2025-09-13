# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "tunnel_token_arn" {
  description = "ARN of the SSM parameter for the Cloudflare tunnel token."
  type        = string
}