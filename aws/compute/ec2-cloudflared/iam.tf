# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# IAM Role for EC2 instances running Cloudflare tunnel
resource "aws_iam_role" "cloudflared" {
  name               = "${var.environment}-cloudflare-tunnel-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-ec2-role"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Trust policy for EC2 instances
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "cloudflared" {
  name = "${var.environment}-cloudflare-tunnel-ec2-profile"
  role = aws_iam_role.cloudflared.name

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-ec2-profile"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Policy for SSM Parameter Store access
resource "aws_iam_policy" "ssm_access" {
  name        = "${var.environment}-cloudflare-tunnel-ssm-policy"
  description = "Allow EC2 instances to retrieve Cloudflare tunnel tokens from SSM"
  policy      = data.aws_iam_policy_document.ssm_access.json

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-ssm-policy"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath"
    ]
    
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/cloudflare/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.tunnel_token_parameter}"
    ]
  }
  
  statement {
    sid    = "DecryptSSMParameters"
    effect = "Allow"
    
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

# Policy for CloudWatch Logs and Metrics
resource "aws_iam_policy" "cloudwatch_access" {
  name        = "${var.environment}-cloudflare-tunnel-cloudwatch-policy"
  description = "Allow EC2 instances to write CloudWatch logs and metrics"
  policy      = data.aws_iam_policy_document.cloudwatch_access.json

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-cloudwatch-policy"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

data "aws_iam_policy_document" "cloudwatch_access" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/cloudflared/*",
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/cloudflared/${var.environment}:*"
    ]
  }
  
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudflareTunnel"]
    }
  }
}

# Policy for Session Manager access (optional)
resource "aws_iam_policy" "session_manager_access" {
  count = var.enable_ssm_session_manager ? 1 : 0
  
  name        = "${var.environment}-cloudflare-tunnel-session-manager-policy"
  description = "Allow EC2 instances to use Systems Manager Session Manager"
  policy      = data.aws_iam_policy_document.session_manager_access.json

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-session-manager-policy"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

data "aws_iam_policy_document" "session_manager_access" {
  statement {
    sid    = "SessionManagerAccess"
    effect = "Allow"
    
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:DescribeInstanceInformation",
      "ssm:DescribeInstanceProperties"
    ]
    
    resources = ["*"]
  }
  
  statement {
    sid    = "SessionManagerMessages"
    effect = "Allow"
    
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    
    resources = ["*"]
  }
  
  statement {
    sid    = "SessionManagerEncryption"
    effect = "Allow"
    
    actions = [
      "kms:Decrypt"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

# Policy for cross-account access (if needed)
resource "aws_iam_policy" "cross_account_access" {
  count = length(var.cross_account_role_arns) > 0 ? 1 : 0
  
  name        = "${var.environment}-cloudflare-tunnel-cross-account-policy"
  description = "Allow EC2 instances to assume roles in other accounts"
  policy      = data.aws_iam_policy_document.cross_account_access[0].json

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-cross-account-policy"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

data "aws_iam_policy_document" "cross_account_access" {
  count = length(var.cross_account_role_arns) > 0 ? 1 : 0
  
  statement {
    sid    = "AssumeRoleInOtherAccounts"
    effect = "Allow"
    
    actions = [
      "sts:AssumeRole"
    ]
    
    resources = values(var.cross_account_role_arns)
  }
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.cloudflared.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.cloudflared.name
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

resource "aws_iam_role_policy_attachment" "session_manager_access" {
  count = var.enable_ssm_session_manager ? 1 : 0
  
  role       = aws_iam_role.cloudflared.name
  policy_arn = aws_iam_policy.session_manager_access[0].arn
}

resource "aws_iam_role_policy_attachment" "cross_account_access" {
  count = length(var.cross_account_role_arns) > 0 ? 1 : 0
  
  role       = aws_iam_role.cloudflared.name
  policy_arn = aws_iam_policy.cross_account_access[0].arn
}

# Attach AWS managed policies for EC2 instance connect and SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  count = var.enable_ssm_session_manager ? 1 : 0
  
  role       = aws_iam_role.cloudflared.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.cloudflared.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
