# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 30
    error_message = "Name prefix must be between 1 and 30 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where the cloudflared instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Specific subnet ID for the cloudflared instance. If not provided, will use the first available private subnet."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for cloudflared"
  type        = string
  default     = "t4g.micro"
  validation {
    condition     = can(regex("^t4g\\.", var.instance_type))
    error_message = "Instance type must be ARM-based (t4g.*) for cost optimization."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 10
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
  }
}

variable "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.tunnel_name))
    error_message = "Tunnel name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tunnel_token_parameter" {
  description = "SSM parameter path containing the Cloudflare tunnel token"
  type        = string
  default     = ""
}

variable "tunnel_routes" {
  description = "List of CIDR blocks to route through the tunnel"
  type = list(object({
    cidr        = string
    region      = string
    description = string
  }))
  default = []
}

variable "cloudflared_version" {
  description = "Version of cloudflared to install"
  type        = string
  default     = "2025.8.1"  # Latest stable version as of Sep 2025
}

variable "enable_cross_account_access" {
  description = "Enable cross-account IAM role assumption"
  type        = bool
  default     = false
}

variable "target_account_ids" {
  description = "List of AWS account IDs that can be accessed from this tunnel"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for account_id in var.target_account_ids : can(regex("^[0-9]{12}$", account_id))
    ])
    error_message = "All target account IDs must be 12-digit numbers."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "metrics_interval" {
  description = "Interval in seconds for cloudflared to send metrics"
  type        = number
  default     = 60
  validation {
    condition     = var.metrics_interval >= 30 && var.metrics_interval <= 300
    error_message = "Metrics interval must be between 30 and 300 seconds."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when CloudWatch alarms trigger"
  type        = list(string)
  default     = []
}

variable "create_status_parameter" {
  description = "Create an SSM parameter with tunnel status information"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_recovery" {
  description = "Enable automatic EC2 instance recovery on failure"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the EC2 instance"
  type        = bool
  default     = true
}

variable "user_data_variables" {
  description = "Additional variables to pass to the user data script"
  type        = map(string)
  default     = {}
}

variable "security_group_ingress_rules" {
  description = "Additional ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "cloudflare_api_endpoint" {
  description = "Cloudflare API endpoint for tunnel registration"
  type        = string
  default     = "https://api.cloudflare.com/client/v4"
}

variable "cloudflare_tunnel_endpoint" {
  description = "Cloudflare tunnel endpoint"
  type        = string
  default     = "https://tunnel.cloudflare.com"
}

variable "enable_ssm_session_manager" {
  description = "Enable AWS Systems Manager Session Manager for instance access"
  type        = bool
  default     = true
}

variable "ssm_parameter_prefix" {
  description = "Prefix for SSM parameters used by the tunnel"
  type        = string
  default     = "/cloudflare/tunnel"
}

variable "dns_servers" {
  description = "Custom DNS servers for the cloudflared instance"
  type        = list(string)
  default     = ["169.254.169.253"]
}

variable "health_check_interval" {
  description = "Interval in seconds between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout in seconds for health checks"
  type        = number
  default     = 10
}

variable "max_retries" {
  description = "Maximum number of retries for cloudflared connection"
  type        = number
  default     = 5
}

variable "retry_interval" {
  description = "Interval in seconds between connection retries"
  type        = number
  default     = 30
}
