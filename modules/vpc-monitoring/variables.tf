# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "vpc_id" {
  description = "VPC ID to monitor"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sdlc, stage, prod)"
  type        = string
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination" {
  description = "Destination for flow logs: s3 or cloudwatch"
  type        = string
  default     = "s3"
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 7
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture: ALL, ACCEPT, or REJECT"
  type        = string
  default     = "ALL"
}

variable "flow_log_aggregation_interval" {
  description = "Flow log aggregation interval in seconds"
  type        = number
  default     = 600
}

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = "notifications@adaptiveworx.com"
}

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs to monitor"
  type        = list(string)
  default     = []
}

variable "nat_gateway_bandwidth_threshold_bytes" {
  description = "Threshold in bytes for NAT Gateway bandwidth alarm"
  type        = number
  default     = 5368709120 # 5GB
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
