# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# CORE VARIABLES
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

# ============================================================================
# FLOW LOG VARIABLES
# ============================================================================

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination" {
  description = "Destination for VPC Flow Logs (s3 or cloudwatch)"
  type        = string
  default     = "s3"
  
  validation {
    condition     = contains(["s3", "cloudwatch"], var.flow_log_destination)
    error_message = "Flow log destination must be either 's3' or 'cloudwatch'."
  }
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to log (ALL, ACCEPT, REJECT)"
  type        = string
  default     = "ALL"
  
  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "Traffic type must be ALL, ACCEPT, or REJECT."
  }
}

variable "flow_log_aggregation_interval" {
  description = "Max interval for flow log aggregation in seconds"
  type        = number
  default     = 600
  
  validation {
    condition     = contains([60, 600], var.flow_log_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30
}

variable "flow_logs_force_destroy" {
  description = "Force destroy S3 bucket even if it contains logs"
  type        = bool
  default     = false
}

# ============================================================================
# MONITORING VARIABLES
# ============================================================================

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms for VPC monitoring"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "nat_gateway_bandwidth_threshold_bytes" {
  description = "Threshold in bytes for NAT Gateway bandwidth alarm"
  type        = number
  default     = 5368709120  # 5 GB
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard for VPC metrics"
  type        = bool
  default     = true
}

# ============================================================================
# COST MANAGEMENT VARIABLES
# ============================================================================

variable "enable_cost_allocation_tags" {
  description = "Enable cost allocation tags for VPC resources"
  type        = bool
  default     = false
}

# ============================================================================
# COMMON VARIABLES
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
