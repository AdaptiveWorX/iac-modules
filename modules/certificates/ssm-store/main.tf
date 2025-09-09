# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-store
# Purpose: Store multi-domain certificates in SSM Parameter Store (worx-secops account)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# KMS key for encrypting private key
resource "aws_kms_key" "certificate_key" {
  description             = "KMS key for certificate private key encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "certificate-encryption-key"
  })
}

resource "aws_kms_alias" "certificate_key" {
  name          = "alias/certificate-encryption"
  target_key_id = aws_kms_key.certificate_key.key_id
}

# Store certificate body
resource "aws_ssm_parameter" "certificate" {
  name        = "/certificates/multi-domain/certificate"
  description = "Multi-domain wildcard certificate body"
  type        = "String"
  value       = var.certificate_body
  tier        = "Standard"

  tags = merge(var.common_tags, {
    Name = "multi-domain-certificate"
  })
}

# Store private key (encrypted)
resource "aws_ssm_parameter" "private_key" {
  name        = "/certificates/multi-domain/private-key"
  description = "Multi-domain wildcard certificate private key (encrypted)"
  type        = "SecureString"
  value       = var.private_key
  key_id      = aws_kms_key.certificate_key.arn
  tier        = "Standard"

  tags = merge(var.common_tags, {
    Name = "multi-domain-private-key"
  })
}

# Store certificate chain
resource "aws_ssm_parameter" "chain" {
  name        = "/certificates/multi-domain/chain"
  description = "Multi-domain wildcard certificate chain"
  type        = "String"
  value       = var.certificate_chain
  tier        = "Standard"

  tags = merge(var.common_tags, {
    Name = "multi-domain-chain"
  })
}

# Store expiry date for reference
resource "aws_ssm_parameter" "expiry" {
  name        = "/certificates/multi-domain/expiry"
  description = "Certificate expiry date (YYYY-MM-DD)"
  type        = "String"
  value       = var.expiry_date
  tier        = "Standard"

  tags = merge(var.common_tags, {
    Name = "multi-domain-expiry"
  })
}

# Cross-account IAM role for certificate access
resource "aws_iam_role" "certificate_reader" {
  name = "certificate-reader"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arns
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "certificate-reader-role"
  })
}

# Policy for reading certificates from SSM
resource "aws_iam_role_policy" "certificate_reader" {
  name = "certificate-reader-policy"
  role = aws_iam_role.certificate_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/certificates/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.certificate_key.arn
        ]
      }
    ]
  })
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Grant KMS key usage to certificate reader role
resource "aws_kms_grant" "certificate_reader" {
  name              = "certificate-reader-grant"
  key_id            = aws_kms_key.certificate_key.id
  grantee_principal = aws_iam_role.certificate_reader.arn
  operations        = ["Decrypt", "DescribeKey"]
}
