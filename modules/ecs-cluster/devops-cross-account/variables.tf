// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting ECS data. If not provided, a new key will be created."
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Whether to create a new KMS key if kms_key_arn is not provided. If false, logs will not be encrypted."
  type        = bool
  default     = false
}

variable "additional_egress_rules" {
  description = "Additional egress rules for ECS tasks security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "task_role_inline_policies" {
  description = "Map of inline IAM policies to attach to the ECS task role (name => policy)"
  type        = map(string)
  default     = {}
}

variable "task_role_managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the ECS task role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 