# Cloudflare Zero Trust Module

## Overview

This module creates a Cloudflare Zero Trust tunnel configuration for secure access to AWS resources. It provides a single-tunnel architecture per environment with automatic region adaptation based on the `regions.yaml` configuration.

## Features

- **Single Tunnel Per Environment**: Simplified architecture with one tunnel per environment
- **Dynamic Route Configuration**: Automatically adapts to enabled regions from `regions.yaml`
- **EC2-Based Deployment**: Cost-optimized using t4g.micro ARM instances (~$6.20/month)
- **Cross-Account Support**: Seamless access to resources across AWS accounts
- **Google Workspace Integration**: Optional Access application with Google authentication
- **Comprehensive Monitoring**: CloudWatch dashboards, metrics, and SNS alerts
- **SSM Parameter Storage**: Secure token storage in AWS Parameter Store

## Usage

```hcl
module "cloudflare_zero_trust" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//cloudflare/zero-trust?ref=v2.0.0"
  
  # Required Variables
  cloudflare_account_id = "your-account-id"
  cloudflare_zone_id    = "your-zone-id"
  environment           = "dev"
  name_prefix           = "worx"
  dns_zone              = "adaptiveworx.com"
  
  # VPC Routes (from regions.yaml)
  vpc_routes = [
    {
      cidr        = "10.0.0.0/16"
      region      = "us-east-1"
      description = "Dev VPC us-east-1"
      enabled     = true
    },
    {
      cidr        = "10.1.0.0/16"
      region      = "us-west-2"
      description = "Dev VPC us-west-2"
      enabled     = true
    }
  ]
  
  # Optional Features
  create_dns_record        = true
  create_access_application = true
  create_dashboard         = true
  create_alerts           = true
  
  # Google Workspace Authentication
  google_workspace_domains = ["adaptiveworx.com"]
  admin_emails            = ["admin@adaptiveworx.com"]
  
  tags = {
    Environment = "dev"
    Project     = "cloudflare-zt"
    ManagedBy   = "terraform"
  }
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `cloudflare_account_id` | string | Cloudflare account ID |
| `cloudflare_zone_id` | string | Cloudflare DNS zone ID |
| `environment` | string | Environment name (dev/staging/prod) |
| `name_prefix` | string | Prefix for resource naming |
| `dns_zone` | string | DNS zone for tunnel endpoints |
| `vpc_routes` | list(object) | List of VPC routes to configure |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_dns_record` | bool | true | Create DNS CNAME for tunnel |
| `create_access_application` | bool | false | Create Zero Trust Access application |
| `create_access_groups` | bool | false | Create Access groups for admins |
| `create_dashboard` | bool | true | Create CloudWatch dashboard |
| `create_alerts` | bool | true | Create CloudWatch alerts |
| `create_webhook` | bool | false | Create webhook endpoint |
| `enable_warp_routing` | bool | false | Enable WARP routing |
| `session_duration` | string | "24h" | Session duration for Access |
| `log_retention_days` | number | 30 | CloudWatch log retention |
| `alert_emails` | list(string) | [] | Email addresses for alerts |
| `admin_emails` | list(string) | [] | Admin email addresses |
| `google_workspace_domains` | list(string) | [] | Google Workspace domains |
| `tags` | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `tunnel_id` | ID of the Cloudflare tunnel |
| `tunnel_name` | Name of the tunnel |
| `tunnel_token` | Authentication token (sensitive) |
| `tunnel_cname` | CNAME endpoint for the tunnel |
| `tunnel_routes` | Configured VPC routes |
| `dns_record` | DNS record details |
| `access_application_id` | Access application ID |
| `ssm_parameters` | SSM parameter paths |
| `cloudwatch_log_group` | CloudWatch log group |
| `cloudwatch_dashboard_url` | Dashboard URL |
| `sns_topic_arn` | SNS topic for alerts |

## Architecture

### Components

1. **Cloudflare Tunnel**: Secure tunnel for private network access
2. **Tunnel Routes**: Dynamic VPC route configuration
3. **DNS Configuration**: Automatic CNAME record creation
4. **Access Application**: Optional Google Workspace authentication
5. **SSM Parameters**: Secure storage of tunnel credentials
6. **CloudWatch Monitoring**: Logs, metrics, and dashboards
7. **SNS Alerts**: Email notifications for tunnel issues

### Security

- Tunnel secrets stored in AWS SSM Parameter Store (SecureString)
- Optional Google Workspace authentication for Access
- CloudWatch logs for audit trails
- IAM policies for least-privilege access

## Migration from ECS-based Module

### Key Differences

1. **Deployment Target**: EC2 instances instead of ECS Fargate
2. **Cost**: ~70% reduction ($6.20/month vs $20-30/month per tunnel)
3. **Architecture**: Single tunnel per environment vs per-region tunnels
4. **Configuration**: Dynamic route adaptation from `regions.yaml`

### Migration Steps

1. Deploy new EC2-based cloudflared instances
2. Create new tunnels with this module
3. Update DNS records to point to new tunnels
4. Test connectivity through new tunnels
5. Decommission old ECS-based infrastructure

## Troubleshooting

### Common Issues

**Tunnel Not Connecting**
- Check SSM parameter for valid token
- Verify EC2 instance is running
- Check CloudWatch logs for errors

**Routes Not Working**
- Verify VPC CIDR blocks in `vpc_routes`
- Check route enabled status
- Confirm tunnel routes in Cloudflare dashboard

**Access Application Issues**
- Verify Google Workspace domain configuration
- Check identity provider settings
- Review Access policies

### Debug Commands

```bash
# Check tunnel status
aws ssm get-parameter --name /dev/cloudflare/tunnel/token --with-decryption

# View CloudWatch logs
aws logs tail /cloudflare/tunnel/dev --follow

# Check EC2 instance status
aws ec2 describe-instances --filters "Name=tag:Purpose,Values=cloudflare-tunnel"
```

## Cost Optimization

### Instance Sizing

- **t4g.micro**: $6.20/month (recommended)
- **t4g.small**: $12.41/month (if more capacity needed)
- **t4g.nano**: $3.10/month (testing only)

### Cost Breakdown (Per Environment)

- EC2 Instance: $6.20/month
- CloudWatch Logs: ~$0.50/month
- SSM Parameters: $0.05/month
- **Total**: ~$6.75/month per environment

## Maintenance

### Regular Tasks

1. **Weekly**: Check CloudWatch dashboards for anomalies
2. **Monthly**: Review CloudWatch logs for errors
3. **Quarterly**: Update cloudflared version
4. **Annually**: Rotate tunnel credentials

### Updates

```bash
# Update module version
terraform init -upgrade

# Apply changes
terraform plan
terraform apply
```

## Support

For issues or questions:
1. Check CloudWatch logs and metrics
2. Review Cloudflare dashboard
3. Contact DevOps team

## License

Copyright (c) Adaptive Technology. All rights reserved.
