// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

# Role for accessing RDS in the target account
resource "aws_iam_role" "rds_access_role" {
  name = var.role_name
  path = "/cross-account/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.source_account_role_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Policy to access RDS instances and operations
resource "aws_iam_policy" "rds_access_policy" {
  name        = "${var.role_name}-policy"
  path        = "/cross-account/"
  description = "Policy for cross-account RDS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBClusterSnapshots",
          "rds:CreateDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:ModifyDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot"
        ]
        Resource = var.rds_arns
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.rds_secret_arns
      }
    ]
  })

  tags = var.tags
}

# If backup bucket access is required
resource "aws_iam_policy" "s3_access_policy" {
  count       = length(var.s3_bucket_arns) > 0 ? 1 : 0
  name        = "${var.role_name}-s3-policy"
  path        = "/cross-account/"
  description = "Policy for cross-account S3 backup bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        )
      }
    ]
  })

  tags = var.tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "rds_access_attachment" {
  role       = aws_iam_role.rds_access_role.name
  policy_arn = aws_iam_policy.rds_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  count      = length(var.s3_bucket_arns) > 0 ? 1 : 0
  role       = aws_iam_role.rds_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy[0].arn
} 