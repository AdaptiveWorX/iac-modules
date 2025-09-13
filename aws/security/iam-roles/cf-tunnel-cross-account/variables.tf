# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "role_name" {
  description = "Name of the IAM role for Cloudflare tunnel cross-account access"
  type        = string
  default     = "CloudflareTunnelAccess"
}

variable "tunnel_role_arn" {
  description = "ARN of the Cloudflare tunnel role in the source account that will assume this role"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/", var.tunnel_role_arn))
    error_message = "Tunnel role ARN must be a valid IAM role ARN."
  }
}

variable "source_account" {
  description = "AWS account ID of the source account (worx-secops)"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.source_account))
    error_message = "Source account must be a 12-digit AWS account ID."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "external_id" {
  description = "External ID for additional security when assuming the role"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.external_id) >= 8
    error_message = "External ID must be at least 8 characters long."
  }
}

variable "allowed_source_ips" {
  description = "List of source IP addresses allowed to assume the role"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.allowed_source_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All source IPs must be valid CIDR blocks."
  }
}

variable "allowed_regions" {
  description = "List of AWS regions where resources can be accessed"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
  validation {
    condition = alltrue([
      for region in var.allowed_regions : can(regex("^[a-z]{2}-[a-z]+-[0-9]$", region))
    ])
    error_message = "All regions must be valid AWS region names."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for assumed role"
  type        = number
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "enable_vpc_access" {
  description = "Enable permissions for VPC and network resource access"
  type        = bool
  default     = true
}

variable "enable_rds_access" {
  description = "Enable permissions for RDS database access"
  type        = bool
  default     = false
}

variable "enable_ecs_access" {
  description = "Enable permissions for ECS container access"
  type        = bool
  default     = false
}

variable "allowed_ecs_clusters" {
  description = "List of ECS cluster names that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_ssm_access" {
  description = "Enable permissions for SSM Session Manager access"
  type        = bool
  default     = true
}

variable "enable_eks_access" {
  description = "Enable permissions for EKS cluster access"
  type        = bool
  default     = false
}

variable "enable_lambda_access" {
  description = "Enable permissions for Lambda function access"
  type        = bool
  default     = false
}

variable "enable_s3_access" {
  description = "Enable permissions for S3 bucket access"
  type        = bool
  default     = false
}

variable "allowed_s3_buckets" {
  description = "List of S3 bucket ARNs that can be accessed"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for bucket in var.allowed_s3_buckets : can(regex("^arn:aws:s3:::", bucket))
    ])
    error_message = "All S3 bucket entries must be valid S3 ARNs."
  }
}

variable "enable_cloudwatch_access" {
  description = "Enable permissions for CloudWatch metrics and logs access"
  type        = bool
  default     = true
}

variable "custom_policy_json" {
  description = "Custom IAM policy JSON for additional permissions"
  type        = string
  default     = ""
  validation {
    condition     = var.custom_policy_json == "" || can(jsondecode(var.custom_policy_json))
    error_message = "Custom policy must be valid JSON or empty string."
  }
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for arn in var.managed_policy_arns : can(regex("^arn:aws:iam::aws:policy/", arn))
    ])
    error_message = "All managed policy ARNs must be valid AWS managed policy ARNs."
  }
}

variable "create_ssm_parameter" {
  description = "Create an SSM parameter to store the role ARN"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_mfa" {
  description = "Require MFA for role assumption"
  type        = bool
  default     = false
}

variable "mfa_age_seconds" {
  description = "Maximum age of MFA authentication in seconds"
  type        = number
  default     = 3600
  validation {
    condition     = var.mfa_age_seconds >= 900 && var.mfa_age_seconds <= 86400
    error_message = "MFA age must be between 900 (15 minutes) and 86400 (24 hours) seconds."
  }
}

variable "enable_secretsmanager_access" {
  description = "Enable permissions for AWS Secrets Manager access"
  type        = bool
  default     = false
}

variable "allowed_secrets_prefixes" {
  description = "List of Secrets Manager secret name prefixes that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_dynamodb_access" {
  description = "Enable permissions for DynamoDB access"
  type        = bool
  default     = false
}

variable "allowed_dynamodb_tables" {
  description = "List of DynamoDB table names that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_sqs_access" {
  description = "Enable permissions for SQS queue access"
  type        = bool
  default     = false
}

variable "allowed_sqs_queues" {
  description = "List of SQS queue ARNs that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_sns_access" {
  description = "Enable permissions for SNS topic access"
  type        = bool
  default     = false
}

variable "allowed_sns_topics" {
  description = "List of SNS topic ARNs that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_ecr_access" {
  description = "Enable permissions for ECR repository access"
  type        = bool
  default     = false
}

variable "allowed_ecr_repositories" {
  description = "List of ECR repository names that can be accessed"
  type        = list(string)
  default     = []
}

variable "enable_elasticache_access" {
  description = "Enable permissions for ElastiCache access"
  type        = bool
  default     = false
}

variable "enable_elasticsearch_access" {
  description = "Enable permissions for Elasticsearch/OpenSearch access"
  type        = bool
  default     = false
}

variable "permission_boundary_arn" {
  description = "ARN of the permissions boundary policy to attach to the role"
  type        = string
  default     = ""
  validation {
    condition     = var.permission_boundary_arn == "" || can(regex("^arn:aws:iam::", var.permission_boundary_arn))
    error_message = "Permission boundary must be a valid IAM policy ARN or empty string."
  }
}

variable "trust_condition_values" {
  description = "Additional condition values for trust relationship"
  type = map(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = {}
}

variable "session_tags" {
  description = "Tags that must be present during role assumption"
  type        = map(string)
  default     = {}
}

variable "transitive_tag_keys" {
  description = "List of tag keys that can be passed during role chaining"
  type        = list(string)
  default     = []
}

variable "require_request_tag" {
  description = "Require specific tags to be present in the assume role request"
  type        = bool
  default     = false
}

variable "allowed_principals" {
  description = "Additional AWS principals that can assume this role"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for principal in var.allowed_principals : can(regex("^arn:aws:iam::", principal))
    ])
    error_message = "All principals must be valid IAM ARNs."
  }
}
