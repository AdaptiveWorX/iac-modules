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

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for IAM policy document
data "aws_iam_policy_document" "tunnel_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "AWS"
      identifiers = [var.tunnel_role_arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
    
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_source_ips
    }
  }
}

# IAM role for Cloudflare tunnel access in target account
resource "aws_iam_role" "cloudflare_tunnel_access" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.tunnel_assume_role.json
  
  description = "Allows Cloudflare tunnel from ${var.source_account} to access resources in this account"
  
  max_session_duration = var.max_session_duration
  
  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      Purpose     = "cloudflare-tunnel-access"
      Environment = var.environment
      SourceAccount = var.source_account
    }
  )
}

# Policy for VPC and network access
data "aws_iam_policy_document" "vpc_access" {
  statement {
    sid = "DescribeVPCResources"
    
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_iam_role_policy" "vpc_access" {
  count = var.enable_vpc_access ? 1 : 0
  
  name   = "${var.role_name}-vpc-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.vpc_access.json
}

# Policy for RDS access
data "aws_iam_policy_document" "rds_access" {
  statement {
    sid = "DescribeRDSResources"
    
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBSecurityGroups",
      "rds:ListTagsForResource"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
  
  statement {
    sid = "ConnectToRDS"
    
    actions = [
      "rds-db:connect"
    ]
    
    resources = [
      "arn:aws:rds-db:*:${data.aws_caller_identity.current.account_id}:dbuser:*/*"
    ]
  }
}

resource "aws_iam_role_policy" "rds_access" {
  count = var.enable_rds_access ? 1 : 0
  
  name   = "${var.role_name}-rds-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.rds_access.json
}

# Policy for ECS access
data "aws_iam_policy_document" "ecs_access" {
  statement {
    sid = "DescribeECSResources"
    
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTasks"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
  
  statement {
    sid = "ExecuteCommand"
    
    actions = [
      "ecs:ExecuteCommand"
    ]
    
    resources = [
      "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = var.allowed_ecs_clusters
    }
  }
}

resource "aws_iam_role_policy" "ecs_access" {
  count = var.enable_ecs_access ? 1 : 0
  
  name   = "${var.role_name}-ecs-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.ecs_access.json
}

# Policy for SSM access
data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid = "StartSSMSession"
    
    actions = [
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus"
    ]
    
    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:session/*"
    ]
    
    condition {
      test     = "StringLike"
      variable = "ssm:resourceTag/Environment"
      values   = [var.environment]
    }
  }
  
  statement {
    sid = "SSMDocumentAccess"
    
    actions = [
      "ssm:GetDocument",
      "ssm:ListDocuments",
      "ssm:ListDocumentVersions",
      "ssm:DescribeDocument",
      "ssm:DescribeDocumentParameters",
      "ssm:DescribeDocumentPermission"
    ]
    
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/SSM-SessionManagerRunShell",
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/AWS-StartPortForwardingSession"
    ]
  }
}

resource "aws_iam_role_policy" "ssm_access" {
  count = var.enable_ssm_access ? 1 : 0
  
  name   = "${var.role_name}-ssm-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.ssm_access.json
}

# Policy for EKS access
data "aws_iam_policy_document" "eks_access" {
  statement {
    sid = "DescribeEKSResources"
    
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:AccessKubernetesApi"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_iam_role_policy" "eks_access" {
  count = var.enable_eks_access ? 1 : 0
  
  name   = "${var.role_name}-eks-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.eks_access.json
}

# Policy for Lambda access
data "aws_iam_policy_document" "lambda_access" {
  statement {
    sid = "InvokeLambdaFunctions"
    
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction"
    ]
    
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_iam_role_policy" "lambda_access" {
  count = var.enable_lambda_access ? 1 : 0
  
  name   = "${var.role_name}-lambda-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.lambda_access.json
}

# Policy for S3 access
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid = "ListS3Buckets"
    
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucketVersions"
    ]
    
    resources = var.allowed_s3_buckets
  }
  
  statement {
    sid = "AccessS3Objects"
    
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectMetadata",
      "s3:GetObjectVersionMetadata"
    ]
    
    resources = [
      for bucket in var.allowed_s3_buckets : "${bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  count = var.enable_s3_access && length(var.allowed_s3_buckets) > 0 ? 1 : 0
  
  name   = "${var.role_name}-s3-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# Policy for CloudWatch access
data "aws_iam_policy_document" "cloudwatch_access" {
  statement {
    sid = "ReadCloudWatchMetrics"
    
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
  
  statement {
    sid = "ReadCloudWatchLogs"
    
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults"
    ]
    
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_access" {
  count = var.enable_cloudwatch_access ? 1 : 0
  
  name   = "${var.role_name}-cloudwatch-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = data.aws_iam_policy_document.cloudwatch_access.json
}

# Policy for custom resource access
resource "aws_iam_role_policy" "custom_access" {
  count = length(var.custom_policy_json) > 0 ? 1 : 0
  
  name   = "${var.role_name}-custom-access"
  role   = aws_iam_role.cloudflare_tunnel_access.id
  policy = var.custom_policy_json
}

# Attach AWS managed policies if specified
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policy_arns)
  
  role       = aws_iam_role.cloudflare_tunnel_access.name
  policy_arn = each.value
}

# Create SSM parameter to store role ARN for easy reference
resource "aws_ssm_parameter" "role_arn" {
  count = var.create_ssm_parameter ? 1 : 0
  
  name  = "/${var.environment}/cloudflare/tunnel/role-arn"
  type  = "String"
  value = aws_iam_role.cloudflare_tunnel_access.arn
  
  description = "IAM role ARN for Cloudflare tunnel cross-account access"
  
  tags = merge(
    var.tags,
    {
      Name        = "/${var.environment}/cloudflare/tunnel/role-arn"
      Purpose     = "cloudflare-tunnel-access"
      Environment = var.environment
    }
  )
}
