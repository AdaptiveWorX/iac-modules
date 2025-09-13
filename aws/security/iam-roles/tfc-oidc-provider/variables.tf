# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "oidc_hostname" {
  type        = string
  description = "The hostname of the OIDC instance"
}

variable "oidc_audience" {
  type        = string
  description = "The OIDC audience value to use in run identity tokens"
}
