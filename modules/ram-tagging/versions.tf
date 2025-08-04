# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
