# VPC Monitoring Module

This module provides comprehensive VPC monitoring capabilities including VPC Flow Logs and CloudWatch alarms for NAT Gateway monitoring. It supports both S3 and CloudWatch Logs as flow log destinations with configurable retention policies.

## Features

- **VPC Flow Logs**: Captures network traffic for security analysis and troubleshooting
- **Dual Destination Support**: S3 (cost-effective) or CloudWatch Logs (real-time analysis)
- **NAT Gateway Monitoring**: CloudWatch alarms for bandwidth and port allocation errors
- **SNS Notifications**: Email alerts for critical monitoring events
- **Configurable Retention**: Automatic cleanup of old logs to manage costs
- **Security Best Practices**: Encrypted storage and secure IAM roles

## Architecture

The module creates a monitoring infrastructure that includes:

- **Flow Log Destination**: S3 bucket or CloudWatch Log Group
- **IAM Role**: Secure permissions for flow log delivery
- **SNS Topic**: Centralized notification system
- **CloudWatch Alarms**: NAT Gateway performance monitoring
- **Lifecycle Policies**: Automatic log retention management

## Usage

### Basic Configuration (S3 Destination)

```hcl
module "vpc_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "prod"
  
  # Flow Log Configuration
  enable_flow_logs              = true
  flow_log_destination          = "s3"  # or "cloudwatch"
  flow_logs_retention_days      = 30
  flow_log_traffic_type         = "ALL"  # ALL, ACCEPT, or REJECT
  flow_log_aggregation_interval = 600    # 10 minutes
  
  # Monitoring Configuration
  enable_monitoring_alarms = true
  alarm_email             = "ops@company.com"
  nat_gateway_ids         = module.vpc_routing.nat_gateway_ids
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

### CloudWatch Logs Destination (Real-time Analysis)

```hcl
module "vpc_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "prod"
  
  # Use CloudWatch for real-time analysis
  flow_log_destination = "cloudwatch"
  flow_logs_retention_days = 7  # CloudWatch retention
  
  # Enable monitoring
  enable_monitoring_alarms = true
  alarm_email             = "security@company.com"
  nat_gateway_ids         = module.vpc_routing.nat_gateway_ids
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

### Cost-Optimized Configuration

```hcl
module "vpc_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "dev"
  
  # Minimal configuration for development
  enable_flow_logs         = true
  flow_log_destination     = "s3"
  flow_logs_retention_days = 7
  flow_log_traffic_type    = "REJECT"  # Only log rejected traffic
  
  # Disable expensive monitoring
  enable_monitoring_alarms = false
  
  tags = {
    Environment = "dev"
    Project     = "infrastructure"
  }
}
```

## Flow Log Analysis

### S3 Flow Logs

Flow logs stored in S3 can be analyzed using:

- **Athena**: SQL queries for traffic analysis
- **CloudTrail**: Integration with security monitoring
- **Third-party tools**: Splunk, ELK stack, etc.

### CloudWatch Flow Logs

CloudWatch logs enable:

- **Real-time monitoring**: Immediate visibility into traffic patterns
- **CloudWatch Insights**: Advanced querying capabilities
- **Integration**: Direct connection to other AWS services

## NAT Gateway Monitoring

The module creates CloudWatch alarms for NAT Gateway health:

### Bandwidth Monitoring
- **Metric**: NATGatewayBytes
- **Threshold**: Configurable (default: 5GB)
- **Action**: SNS notification when bandwidth exceeds threshold

### Port Allocation Errors
- **Metric**: NATGatewayErrorPortAllocation
- **Threshold**: Any error count > 0
- **Action**: Immediate SNS notification for troubleshooting

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | VPC ID to monitor | string | n/a | yes |
| environment | Environment name (e.g., sdlc, stage, prod) | string | n/a | yes |
| enable_flow_logs | Enable VPC Flow Logs | bool | true | no |
| flow_log_destination | Destination for flow logs: s3 or cloudwatch | string | "s3" | no |
| flow_logs_retention_days | Number of days to retain flow logs | number | 7 | no |
| flow_log_traffic_type | Type of traffic to capture: ALL, ACCEPT, or REJECT | string | "ALL" | no |
| flow_log_aggregation_interval | Flow log aggregation interval in seconds | number | 600 | no |
| enable_monitoring_alarms | Enable CloudWatch alarms for monitoring | bool | true | no |
| alarm_email | Email address for alarm notifications | string | n/a | no |
| nat_gateway_ids | List of NAT Gateway IDs to monitor | list(string) | [] | no |
| nat_gateway_bandwidth_threshold_bytes | Threshold in bytes for NAT Gateway bandwidth alarm | number | 5368709120 | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| flow_log_id | ID of the VPC Flow Log |
| flow_log_s3_bucket_arn | ARN of the S3 bucket for VPC Flow Logs |
| flow_log_cloudwatch_log_group_name | Name of the CloudWatch Log Group for VPC Flow Logs |
| sns_topic_arn | ARN of the SNS topic for alarms |
| nat_gateway_bandwidth_alarm_names | Names of NAT Gateway bandwidth alarms |
| nat_gateway_port_allocation_alarm_names | Names of NAT Gateway port allocation error alarms |

## Cost Considerations

### Flow Log Costs

**S3 Storage:**
- ~$0.023 per GB per month
- Lifecycle policies automatically delete old logs

**CloudWatch Logs:**
- ~$0.50 per GB ingested
- ~$0.03 per GB stored per month
- Additional charges for CloudWatch Insights queries

### Optimization Strategies

1. **Development Environments**: Use S3 with short retention (7 days)
2. **Production**: Use CloudWatch for real-time monitoring, S3 for long-term storage
3. **Traffic Filtering**: Use `flow_log_traffic_type = "REJECT"` to reduce log volume
4. **Aggregation**: Increase `flow_log_aggregation_interval` to reduce costs

## Security Considerations

### IAM Permissions
The module creates a minimal IAM role with only necessary permissions:
- `logs:CreateLogGroup` and `logs:CreateLogStream` (CloudWatch)
- `s3:PutObject` (S3 bucket)
- `s3:GetBucketLocation` (S3 bucket discovery)

### Data Protection
- S3 bucket encryption enabled by default
- Public access blocked on S3 bucket
- CloudWatch logs encrypted at rest

## Troubleshooting

### Flow Logs Not Appearing

1. **Check IAM Permissions**: Verify the flow log role has correct permissions
2. **Verify Destination**: Ensure S3 bucket exists or CloudWatch log group is accessible
3. **Check Traffic**: Confirm there's actual traffic in the VPC

### Alarms Not Triggering

1. **Verify NAT Gateway IDs**: Ensure correct NAT Gateway IDs are provided
2. **Check SNS Topic**: Verify email subscription is confirmed
3. **Review Thresholds**: Adjust bandwidth thresholds if needed

### High Costs

1. **Reduce Retention**: Lower `flow_logs_retention_days`
2. **Filter Traffic**: Use `flow_log_traffic_type = "REJECT"`
3. **Increase Aggregation**: Set higher `flow_log_aggregation_interval`

## Examples

### Production Monitoring Setup

```hcl
module "prod_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "prod"
  
  # Comprehensive monitoring
  enable_flow_logs              = true
  flow_log_destination          = "cloudwatch"
  flow_logs_retention_days      = 30
  flow_log_traffic_type         = "ALL"
  flow_log_aggregation_interval = 60  # 1 minute for real-time
  
  # NAT Gateway monitoring
  enable_monitoring_alarms = true
  alarm_email             = "prod-ops@company.com"
  nat_gateway_ids         = module.vpc_routing.nat_gateway_ids
  
  tags = {
    Environment = "prod"
    CostCenter  = "engineering"
    Compliance  = "SOC2"
  }
}
```

### Development Monitoring Setup

```hcl
module "dev_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "dev"
  
  # Cost-optimized configuration
  enable_flow_logs         = true
  flow_log_destination     = "s3"
  flow_logs_retention_days = 7
  flow_log_traffic_type    = "REJECT"  # Only security events
  
  # No expensive monitoring
  enable_monitoring_alarms = false
  
  tags = {
    Environment = "dev"
    Project     = "infrastructure"
  }
}
```

## Requirements

- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0
- VPC Core module must be deployed first

## License

Copyright (c) Adaptive Technology. All rights reserved.
Licensed under the Apache-2.0 License. 