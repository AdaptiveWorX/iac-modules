# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}