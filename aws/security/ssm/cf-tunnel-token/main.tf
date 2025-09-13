# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter
resource "aws_ssm_parameter" "tunneltoken" {
  name  = "${var.prefix}-cf-tunnel-token"
  type  = "SecureString"
  value = var.tunnel_token
  
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}