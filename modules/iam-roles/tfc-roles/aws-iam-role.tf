# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
    }
  }
}

# Creates an IAM role which can only be used with the specified Terraform Cloud OIDC provider.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "iam_role" {
  name = "tfc-${var.aws_account_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
            Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:aud" = var.oidc_audience
          },
          StringLike = {
            "${var.oidc_provider_url}:sub": "organization:${var.organization}:project:${var.project}:workspace:${var.workspace}:run_phase:*"
          }
        }
      }
    ]
  })

  # tags = {
  #   Environment = var.environment
  #   Project     = var.project
  #   ManagedBy   = "Terraform"
  #   Owner       = "SecOps"
  # }
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name = "tfc-${var.aws_account_name}-policy"
  count  = length(var.policy_files)
  role   = aws_iam_role.iam_role.id
  policy = file("${path.module}/policies/${var.policy_files[count.index]}")
}
