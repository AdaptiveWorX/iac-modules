# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the Cloudflare tunnel"
  type        = string
  default     = "t4g.nano"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "VPC ID where the tunnel instances will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "tunnel_token_parameter" {
  description = "SSM Parameter name containing the Cloudflare tunnel token"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = "f23ad949750ddaf360446a334bffdc3d"
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling based on CPU utilization"
  type        = bool
  default     = true
}

variable "enable_auto_recovery" {
  description = "Enable auto-recovery for failed instances"
  type        = bool
  default     = true
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance launch before checking health"
  type        = number
  default     = 300
}

variable "cross_account_role_arns" {
  description = "Map of environment to cross-account role ARNs for access"
  type        = map(string)
  default     = {}
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the instances (usually not needed)"
  type        = list(string)
  default     = []
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks for egress traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cloudwatch_log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_ssm_session_manager" {
  description = "Enable AWS Systems Manager Session Manager for instance access"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "enable_ebs_encryption" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

variable "ebs_kms_key_id" {
  description = "KMS key ID for EBS volume encryption"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Type of the root EBS volume"
  type        = string
  default     = "gp3"
}

variable "enable_termination_protection" {
  description = "Enable termination protection for the Auto Scaling Group"
  type        = bool
  default     = false
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for Auto Scaling notifications"
  type        = string
  default     = ""
}

variable "cloudflare_dns_hostname" {
  description = "DNS hostname for the Cloudflare tunnel"
  type        = string
  default     = ""
}

# Cross-Account Access Configuration
variable "enable_cross_account_access" {
  description = "Enable creation of cross-account role in target account"
  type        = bool
  default     = false
}

variable "target_account_id" {
  description = "Target AWS account ID for cross-account access"
  type        = string
  default     = ""
}

variable "target_account_role_arn" {
  description = "ARN of the role to assume in target account for creating cross-account resources"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
