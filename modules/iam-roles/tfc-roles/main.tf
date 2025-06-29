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

# Create the TFC role for OIDC authentication
data "aws_iam_policy_document" "tfc_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Federated"
      identifiers = [
        var.oidc_provider_arn
      ]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = [var.oidc_audience]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["organization:${var.organization}:project:${var.project}:workspace:${var.workspace}:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "tfc_role" {
  name               = "${var.aws_account_name}-tfc-role"
  assume_role_policy = data.aws_iam_policy_document.tfc_assume_role.json

  tags = {
    Name      = "${var.aws_account_name}-tfc-role"
    Account   = replace(var.aws_account_name, "/[^a-zA-Z0-9_+=,.@-]/", "-")
    ManagedBy = "terraform-cloud"
  }
}

# Attach policies to the TFC role
resource "aws_iam_role_policy" "tfc_policy" {
  count  = length(var.policy_files)
  name   = "${replace(basename(var.policy_files[count.index]), ".json", "")}-tfc-policy"
  role   = aws_iam_role.tfc_role.id
  policy = file("${path.module}/policies/${var.policy_files[count.index]}")
}

# Create cross-account role if enabled
data "aws_iam_policy_document" "tfc_secops_xa_assume_role" {
  count = var.enable_cross_account ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.secops_account_id}:root"
      ]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/Project"
      values   = ["SecOps"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.secops_account_id}:role/${var.aws_account_name}-tfc-role"]
    }
  }
}

resource "aws_iam_role" "tfc_secops_xa_role" {
  count              = var.enable_cross_account ? 1 : 0
  name               = "${var.aws_account_name}-tfc-xa-role"
  assume_role_policy = data.aws_iam_policy_document.tfc_secops_xa_assume_role[0].json

  tags = {
    Name        = "${var.aws_account_name}-tfc-xa-role"
    Account     = replace(var.aws_account_name, "/[^a-zA-Z0-9_+=,.@-]/", "-")
    ManagedBy   = "terraform-cloud"
    CrossAccess = "true"
  }
}

resource "aws_iam_role_policy" "tfc_secops_xa_policy" {
  count  = var.enable_cross_account ? length(var.policy_files) : 0
  name   = "${replace(basename(var.policy_files[count.index]), ".json", "")}-tfc-xa-policy"
  role   = aws_iam_role.tfc_secops_xa_role[0].id
  policy = file("${path.module}/policies/${var.policy_files[count.index]}")
}
