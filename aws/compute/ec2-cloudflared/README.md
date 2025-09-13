# EC2-based Cloudflared Module

## Overview

This module deploys a cost-optimized EC2 instance running cloudflared to establish secure Cloudflare Zero Trust tunnels. It uses ARM-based t4g.micro instances for significant cost savings (~$6/month per instance) compared to ECS Fargate deployments.

## Features

- **ARM Architecture**: Uses t4g.micro instances for 70% cost reduction
- **Auto-recovery**: Automatic instance recovery on failures
- **CloudWatch Integration**: Comprehensive logging and metrics
- **Cross-account Support**: Optional IAM roles for multi-account access
- **Dynamic Configuration**: Adapts to regions.yaml configuration
- **Health Monitoring**: Built-in health checks and auto-restart
- **Secure by Default**: IMDSv2, encrypted volumes, minimal permissions

## Usage

### Basic Example

```hcl
module "cloudflared" {
  source = "../../modules/aws/compute/ec2-cloudflared"

  name_prefix    = "worx-dev"
  environment    = "dev"
  vpc_id         = module.vpc.vpc_id
  tunnel_name    = "worx-dev-tunnel"
  region         = "us-east-1"
  
  tunnel_token_parameter = "/dev/cloudflare/tunnel/token"
  
  tunnel_routes = [
    {
      cidr        = "10.0.0.0/16"
      region      = "us-east-1"
      description = "Dev VPC - US East 1"
    },
    {
      cidr        = "10.1.0.0/16"
      region      = "us-west-2"
      description = "Dev VPC - US West 2"
    }
  ]
  
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Purpose     = "CloudflareZeroTrust"
  }
}
```

### Cross-Account Access Example

```hcl
module "cloudflared_with_cross_account" {
  source = "../../modules/aws/compute/ec2-cloudflared"

  name_prefix    = "worx-secops"
  environment    = "prod"
  vpc_id         = var.vpc_id
  tunnel_name    = "worx-central-tunnel"
  
  # Enable cross-account access
  enable_cross_account_access = true
  target_account_ids = [
    "413639306030",  # dev
    "335746353051",  # staging
    "436083577402"   # prod
  ]
  
  # CloudWatch alarms
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  # Enhanced monitoring
  enable_detailed_monitoring = true
  log_retention_days        = 30
  metrics_interval           = 30
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for all resource names | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID where the cloudflared instance will be deployed | `string` | n/a | yes |
| tunnel_name | Name of the Cloudflare tunnel | `string` | n/a | yes |
| subnet_id | Specific subnet ID for the cloudflared instance | `string` | `""` | no |
| region | AWS region for deployment | `string` | `"us-east-1"` | no |
| instance_type | EC2 instance type for cloudflared | `string` | `"t4g.micro"` | no |
| root_volume_size | Size of the root EBS volume in GB | `number` | `10` | no |
| tunnel_token_parameter | SSM parameter path containing the Cloudflare tunnel token | `string` | `""` | no |
| tunnel_routes | List of CIDR blocks to route through the tunnel | `list(object)` | `[]` | no |
| cloudflared_version | Version of cloudflared to install | `string` | `"2024.2.1"` | no |
| enable_cross_account_access | Enable cross-account IAM role assumption | `bool` | `false` | no |
| target_account_ids | List of AWS account IDs that can be accessed from this tunnel | `list(string)` | `[]` | no |
| log_retention_days | CloudWatch log retention period in days | `number` | `7` | no |
| metrics_interval | Interval in seconds for cloudflared to send metrics | `number` | `60` | no |
| alarm_actions | List of ARNs to notify when CloudWatch alarms trigger | `list(string)` | `[]` | no |
| create_status_parameter | Create an SSM parameter with tunnel status information | `bool` | `true` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the EC2 instance running cloudflared |
| instance_arn | ARN of the EC2 instance |
| private_ip | Private IP address of the cloudflared instance |
| security_group_id | Security group ID for the cloudflared instance |
| iam_role_arn | IAM role ARN for the cloudflared instance |
| cloudwatch_log_group_name | CloudWatch log group name for cloudflared logs |
| tunnel_configuration | Tunnel configuration details |
| network_configuration | Network configuration for the cloudflared instance |

## Instance Configuration

### Instance Type Selection

The module enforces ARM-based instance types (t4g.*) for cost optimization:
- **t4g.micro**: Recommended for most use cases (1 vCPU, 1GB RAM)
- **t4g.small**: For higher traffic environments (2 vCPU, 2GB RAM)
- **t4g.medium**: For production workloads (2 vCPU, 4GB RAM)

### Security Configuration

The instance is configured with multiple security layers:
- **IMDSv2 Required**: Instance metadata service v2 is enforced
- **Encrypted EBS Volumes**: All volumes are encrypted by default
- **Minimal IAM Permissions**: Only necessary permissions for SSM and CloudWatch
- **Security Group**: Restrictive egress-only rules
- **No SSH Access**: Instance access via SSM Session Manager only

## Monitoring and Alerting

### CloudWatch Metrics

The module automatically publishes the following metrics to CloudWatch:
- **TunnelStatus**: Binary status of the tunnel (0=down, 1=up)
- **ActiveConnections**: Number of active connections through the tunnel
- **TunnelRegistered**: Registration status with Cloudflare
- **CPU/Memory/Disk**: Standard EC2 metrics

### CloudWatch Alarms

Pre-configured alarms include:
- **Status Check Failed**: Triggers when instance fails status checks
- **High CPU Utilization**: Alerts when CPU > 80%
- **Auto-recovery**: Automatically recovers failed instances

### Logging

All logs are sent to CloudWatch Logs:
- **Setup Logs**: `/aws/ec2/cloudflared/{environment}/setup`
- **Runtime Logs**: `/aws/ec2/cloudflared/{environment}/cloudflared`
- **Health Check Logs**: Stored locally with rotation

## Cloudflared Configuration

### User Data Script

The user data script performs the following actions:
1. Updates system packages
2. Installs cloudflared binary (ARM architecture)
3. Retrieves tunnel token from SSM Parameter Store
4. Configures cloudflared with appropriate settings
5. Sets up systemd service with auto-restart
6. Configures CloudWatch agent for monitoring
7. Implements health checks with auto-recovery

### Configuration File

The cloudflared configuration (`/etc/cloudflared/config.yml`) includes:
- Tunnel name and credentials
- Metrics endpoint configuration
- Logging settings
- Protocol configuration (QUIC)
- Retry and grace period settings

### Health Checks

Health checks run every 5 minutes and verify:
- Cloudflared service is running
- Tunnel is connected to Cloudflare
- Metrics endpoint is responsive

## Cross-Account Access

When `enable_cross_account_access` is enabled, the module creates IAM policies allowing the instance to assume roles in target accounts. This enables centralized tunnel management while maintaining security boundaries.

### Required Target Account Setup

In each target account, create a role with the following trust relationship:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::SECOPS_ACCOUNT_ID:role/PREFIX-cloudflared-role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Cost Optimization

### Instance Costs (Monthly)
- **t4g.micro**: ~$6.20 (1 vCPU, 1GB RAM)
- **t4g.small**: ~$12.40 (2 vCPU, 2GB RAM)
- **t4g.medium**: ~$24.80 (2 vCPU, 4GB RAM)

### Additional Costs
- **EBS Volume**: ~$0.80 (10GB gp3)
- **CloudWatch Logs**: ~$0.50 (estimated)
- **Data Transfer**: Variable based on usage

### Total Estimated Cost
**~$7.50/month** per tunnel (t4g.micro with standard configuration)

## Troubleshooting

### Common Issues

1. **Tunnel Not Connecting**
   - Check SSM parameter contains valid tunnel token
   - Verify security group allows egress to Cloudflare
   - Review CloudWatch logs for authentication errors

2. **High CPU Usage**
   - Consider upgrading to t4g.small
   - Check for excessive connection attempts
   - Review tunnel routes for loops

3. **Instance Failing Health Checks**
   - Check CloudWatch logs for errors
   - Verify DNS resolution is working
   - Ensure cloudflared binary is compatible with ARM

### Debug Commands

Connect to instance via SSM Session Manager:
```bash
aws ssm start-session --target INSTANCE_ID --region REGION
```

Check cloudflared status:
```bash
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 100
```

View metrics:
```bash
curl http://localhost:2000/metrics
curl http://localhost:2000/ready
```

## Migration from ECS

### Key Differences
- **Cost**: 70% reduction compared to Fargate
- **Simplicity**: Single EC2 instance vs ECS cluster
- **Maintenance**: Automatic updates via user data
- **Monitoring**: Native CloudWatch integration

### Migration Steps
1. Deploy new EC2-based tunnel
2. Update DNS records to point to new tunnel
3. Monitor both tunnels during transition
4. Decommission ECS cluster after validation

## Security Considerations

### Best Practices
- Store tunnel tokens in SSM Parameter Store with encryption
- Use separate tunnels for each environment
- Enable detailed monitoring and alerting
- Regularly update cloudflared version
- Review security group rules periodically

### Compliance
- All data in transit is encrypted via TLS
- No data is stored on the instance
- Logs are retained according to policy
- Instance access is audit-logged via SSM

## Support

For issues or questions:
1. Check CloudWatch Logs for detailed error messages
2. Review the troubleshooting section above
3. Consult Cloudflare Zero Trust documentation
4. Contact the platform team

## License

This module is maintained by the AdaptiveWorX Platform Team.
