# Cross-Account IAM Role for Cloudflare Tunnel

## Overview

This module creates IAM roles in target AWS accounts that allow the Cloudflare tunnel EC2 instance from the worx-secops account to access resources across multiple accounts. It provides fine-grained permissions control with support for various AWS services.

## Features

- **Secure Cross-Account Access**: External ID and IP restrictions for enhanced security
- **Service-Specific Permissions**: Enable only the services you need
- **Regional Restrictions**: Limit access to specific AWS regions
- **MFA Support**: Optional MFA requirement for role assumption
- **Audit Trail**: CloudTrail logs all cross-account access
- **SSM Parameter Storage**: Automatic storage of role ARN for easy reference

## Usage

### Basic Example

```hcl
module "cloudflare_tunnel_access" {
  source = "../../modules/aws/security/iam-roles/cf-tunnel-cross-account"

  role_name        = "CloudflareTunnelAccess"
  tunnel_role_arn  = "arn:aws:iam::730335555486:role/worx-secops-cloudflared-role"
  source_account   = "730335555486"  # worx-secops
  environment      = "dev"
  external_id      = var.external_id  # Store in Terraform Cloud or AWS Secrets Manager
  
  # Enable required services
  enable_vpc_access        = true
  enable_ssm_access        = true
  enable_cloudwatch_access = true
  
  allowed_regions = ["us-east-1", "us-west-2"]
  
  tags = {
    Environment = "dev"
    Purpose     = "CloudflareZeroTrust"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Example with Multiple Services

```hcl
module "cloudflare_tunnel_full_access" {
  source = "../../modules/aws/security/iam-roles/cf-tunnel-cross-account"

  role_name        = "CloudflareTunnelAccess"
  tunnel_role_arn  = "arn:aws:iam::730335555486:role/worx-secops-cloudflared-role"
  source_account   = "730335555486"
  environment      = "prod"
  external_id      = var.external_id
  
  # Network access
  enable_vpc_access = true
  allowed_regions   = ["us-east-1", "us-west-2", "eu-west-1"]
  
  # Database access
  enable_rds_access = true
  
  # Container access
  enable_ecs_access    = true
  allowed_ecs_clusters = ["prod-api", "prod-workers"]
  
  # Kubernetes access
  enable_eks_access = true
  
  # Storage access
  enable_s3_access    = true
  allowed_s3_buckets  = [
    "arn:aws:s3:::prod-assets",
    "arn:aws:s3:::prod-backups"
  ]
  
  # Function access
  enable_lambda_access = true
  
  # Session management
  enable_ssm_access = true
  
  # Monitoring
  enable_cloudwatch_access = true
  
  # Security settings
  max_session_duration = 7200  # 2 hours
  allowed_source_ips   = ["10.0.0.0/8"]  # Internal network only
  
  tags = {
    Environment = "prod"
    Purpose     = "CloudflareZeroTrust"
    Compliance  = "SOC2"
  }
}
```

### Cross-Account Setup in Target Account

Deploy this module in each target account (dev, staging, prod) where you need tunnel access:

```hcl
# In worx-dev account (413639306030)
module "cf_tunnel_access_dev" {
  source = "../../../modules/aws/security/iam-roles/cf-tunnel-cross-account"
  
  role_name        = "CloudflareTunnelAccess"
  tunnel_role_arn  = "arn:aws:iam::730335555486:role/worx-dev-cloudflared-role"
  source_account   = "730335555486"
  environment      = "dev"
  external_id      = data.aws_ssm_parameter.cf_external_id.value
  
  # ... service configurations
}

# In worx-staging account (335746353051)
module "cf_tunnel_access_staging" {
  source = "../../../modules/aws/security/iam-roles/cf-tunnel-cross-account"
  
  role_name        = "CloudflareTunnelAccess"
  tunnel_role_arn  = "arn:aws:iam::730335555486:role/worx-staging-cloudflared-role"
  source_account   = "730335555486"
  environment      = "staging"
  external_id      = data.aws_ssm_parameter.cf_external_id.value
  
  # ... service configurations
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
| role_name | Name of the IAM role | `string` | `"CloudflareTunnelAccess"` | no |
| tunnel_role_arn | ARN of the tunnel role in source account | `string` | n/a | yes |
| source_account | AWS account ID of the source account | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| external_id | External ID for role assumption | `string` | n/a | yes |
| allowed_source_ips | List of source IPs allowed to assume role | `list(string)` | `[]` | no |
| allowed_regions | List of AWS regions where resources can be accessed | `list(string)` | `["us-east-1", "us-west-2"]` | no |
| max_session_duration | Maximum session duration in seconds | `number` | `3600` | no |
| enable_vpc_access | Enable VPC and network resource access | `bool` | `true` | no |
| enable_rds_access | Enable RDS database access | `bool` | `false` | no |
| enable_ecs_access | Enable ECS container access | `bool` | `false` | no |
| enable_ssm_access | Enable SSM Session Manager access | `bool` | `true` | no |
| enable_eks_access | Enable EKS cluster access | `bool` | `false` | no |
| enable_lambda_access | Enable Lambda function access | `bool` | `false` | no |
| enable_s3_access | Enable S3 bucket access | `bool` | `false` | no |
| enable_cloudwatch_access | Enable CloudWatch access | `bool` | `true` | no |
| allowed_ecs_clusters | List of ECS clusters that can be accessed | `list(string)` | `[]` | no |
| allowed_s3_buckets | List of S3 bucket ARNs that can be accessed | `list(string)` | `[]` | no |
| custom_policy_json | Custom IAM policy JSON | `string` | `""` | no |
| managed_policy_arns | AWS managed policies to attach | `list(string)` | `[]` | no |
| create_ssm_parameter | Create SSM parameter for role ARN | `bool` | `true` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| external_id | External ID for role assumption |
| enabled_services | Map of enabled service permissions |
| ssm_parameter_name | SSM parameter name storing role ARN |
| assume_role_command | AWS CLI command to assume the role |
| cross_account_configuration | Complete cross-account configuration |

## Security Configuration

### Trust Relationship

The module creates a trust relationship with the following security controls:

1. **Principal Restriction**: Only the specified tunnel role can assume this role
2. **External ID**: Required for all role assumptions
3. **IP Restrictions**: Optional source IP filtering
4. **MFA**: Optional MFA requirement

Example trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::730335555486:role/cloudflared-role"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        },
        "IpAddress": {
          "aws:SourceIp": ["10.0.0.0/8"]
        }
      }
    }
  ]
}
```

### Service Permissions

Each service can be individually enabled with appropriate permissions:

#### VPC Access
- Describe VPCs, subnets, security groups
- View network interfaces and route tables
- Read EC2 instance information

#### RDS Access
- Describe database instances and clusters
- Connect to RDS databases
- List database tags

#### ECS Access
- Describe clusters, services, and tasks
- Execute commands in containers
- View task definitions

#### SSM Access
- Start and manage SSM sessions
- Access Session Manager documents
- Connect to EC2 instances

#### S3 Access
- List specified buckets
- Read objects from allowed buckets
- No write permissions

#### CloudWatch Access
- Read metrics and alarms
- Query logs and insights
- No write permissions

## Cross-Account Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    worx-secops (730335555486)               │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │         EC2 Instance (Cloudflared Tunnel)          │    │
│  │                                                    │    │
│  │  IAM Role: worx-secops-cloudflared-role           │    │
│  └────────────────────────────────────────────────────┘    │
│                            │                                │
└────────────────────────────┼────────────────────────────────┘
                             │
                    AssumeRole with External ID
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        v                    v                    v
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   worx-dev   │    │ worx-staging │    │  worx-prod   │
│ (413639306030)│    │(335746353051)│    │(436083577402)│
│              │    │              │    │              │
│ IAM Role:    │    │ IAM Role:    │    │ IAM Role:    │
│ Cloudflare   │    │ Cloudflare   │    │ Cloudflare   │
│ TunnelAccess │    │ TunnelAccess │    │ TunnelAccess │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Best Practices

### Security
1. **External ID**: Always use a strong, unique external ID
2. **Least Privilege**: Enable only required services
3. **Regional Restrictions**: Limit to necessary regions
4. **IP Restrictions**: Use when tunnel has static IPs
5. **Session Duration**: Keep as short as practical
6. **Regular Audits**: Review CloudTrail logs regularly

### Implementation
1. Deploy role in each target account
2. Store external ID securely (SSM Parameter Store or Secrets Manager)
3. Document which services are enabled per environment
4. Use consistent role names across accounts
5. Tag resources for cost tracking and compliance

### Monitoring
1. Enable CloudTrail logging for all AssumeRole events
2. Set up CloudWatch alarms for unusual access patterns
3. Monitor session duration and frequency
4. Track which services are being accessed

## Troubleshooting

### Common Issues

1. **Access Denied on AssumeRole**
   - Verify external ID matches
   - Check source IP restrictions
   - Ensure tunnel role ARN is correct
   - Verify trust relationship is properly configured

2. **Service Access Denied**
   - Check if service is enabled in module
   - Verify regional restrictions
   - Check resource-specific permissions
   - Review policy conditions

3. **Session Expired**
   - Check max_session_duration setting
   - Verify credentials are being refreshed
   - Monitor CloudTrail for session termination

### Debug Commands

Test role assumption:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/CloudflareTunnelAccess \
  --role-session-name test-session \
  --external-id YOUR_EXTERNAL_ID
```

Check role policies:
```bash
aws iam get-role --role-name CloudflareTunnelAccess
aws iam list-role-policies --role-name CloudflareTunnelAccess
aws iam list-attached-role-policies --role-name CloudflareTunnelAccess
```

## Migration Guide

### From ECS to EC2

1. **Update Trust Relationship**
   - Change principal from ECS task role to EC2 instance role
   - Update external ID if needed

2. **Review Permissions**
   - Remove ECS-specific permissions
   - Add EC2/SSM permissions if needed

3. **Update Module Source**
   ```hcl
   # Old
   source = "../modules/iam/ecs-cross-account"
   
   # New
   source = "../modules/aws/security/iam-roles/cf-tunnel-cross-account"
   ```

## Compliance

This module supports compliance requirements:
- **SOC2**: Audit trails via CloudTrail
- **HIPAA**: Encryption in transit, limited access
- **PCI**: Least privilege, session management
- **ISO 27001**: Access controls, monitoring

## Support

For issues or questions:
1. Check CloudTrail logs for access attempts
2. Review IAM policy simulator results
3. Verify module configuration
4. Contact the platform team

## License

This module is maintained by the AdaptiveWorX Platform Team.
