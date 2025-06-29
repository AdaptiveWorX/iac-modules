# VPC Sharing Module

This module manages AWS Resource Access Manager (RAM) shares for VPC resources, enabling secure cross-account access to VPC subnets within an AWS Organization.

## Features

- Share VPC subnets with specific AWS accounts
- Share VPC subnets with AWS Organization units
- Enable RAM sharing with AWS Organizations (requires management account permissions)
- Automatic resource association management
- Support for multi-provider configurations
- Comprehensive tagging support

## Architecture

The module creates the following sharing architecture:

- **RAM Resource Share**: Central share container for VPC resources
- **Resource Associations**: Links subnets to the share
- **Principal Associations**: Grants access to specific accounts or OUs
- **Organization Integration**: Optional AWS Organizations-wide sharing

## Usage

### Basic Account-to-Account Sharing

```hcl
module "vpc_sharing" {
  source = "git::git@github.com:AdaptiveWorX/iac-modules.git//modules/vpc-sharing?ref=v1.0.0"

  environment = "prod"
  subnet_arns = [
    "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345",
    "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-67890"
  ]
  
  share_with_accounts = ["987654321098", "876543210987"]
  
  # Disable org sharing if not using management account
  enable_org_sharing = false
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

### Organization Unit Sharing

```hcl
module "vpc_sharing" {
  source = "git::git@github.com:AdaptiveWorX/iac-modules.git//modules/vpc-sharing?ref=v1.0.0"

  environment = "prod"
  subnet_arns = module.vpc_core.private_subnet_ids
  
  # Share with entire organization unit
  share_with_org_unit = true
  org_unit_arn       = "arn:aws:organizations::123456789012:ou/o-abc123/ou-def456"
  
  # Enable organization-wide sharing
  enable_org_sharing = true
  
  # Configure providers for org management
  providers = {
    aws                = aws
    aws.org_management = aws.org_management
  }
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

### Mixed Sharing Strategy

```hcl
module "vpc_sharing" {
  source = "git::git@github.com:AdaptiveWorX/iac-modules.git//modules/vpc-sharing?ref=v1.0.0"

  environment = "prod"
  
  # Share specific subnets
  subnet_arns = concat(
    module.vpc_core.private_subnet_ids,
    module.vpc_core.data_subnet_ids
  )
  
  # Share with specific accounts
  share_with_accounts = ["987654321098"]
  
  # Also share with an OU
  share_with_org_unit = true
  org_unit_arn       = "arn:aws:organizations::123456789012:ou/o-abc123/ou-def456"
  
  enable_org_sharing = true
  
  providers = {
    aws                = aws
    aws.org_management = aws.org_management
  }
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

## Provider Configuration

This module supports two provider configurations:

1. **Default provider** (`aws`) - Used for creating RAM shares and associations
2. **Organization management provider** (`aws.org_management`) - Used for enabling RAM sharing with AWS Organizations

### Example Provider Configuration in Terragrunt

```hcl
terraform {
  extra_arguments "providers" {
    commands = ["init", "plan", "apply", "destroy"]
    arguments = []
    env_vars = {
      AWS_PROFILE = "adaptive-secops"  # Default profile
    }
  }
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}

provider "aws" {
  alias   = "org_management"
  region  = "${local.aws_region}"
  profile = "adaptive-master"  # Management account profile
}
EOF
}
```

## Shared Resource Permissions

When subnets are shared via RAM, the following permissions are granted to principals:

- **EC2 Instance Launch**: Launch instances in shared subnets
- **Network Interface Management**: Create/modify ENIs in shared subnets
- **Security Group Association**: Attach security groups to resources
- **Route Table Association**: Cannot modify route tables (owner account only)
- **NACL Management**: Cannot modify NACLs (owner account only)

## Best Practices

### Security Considerations

1. **Principle of Least Privilege**: Only share subnets that need cross-account access
2. **Subnet Selection**: Consider sharing private subnets only, not public subnets
3. **Account Validation**: Verify account IDs before sharing to prevent unauthorized access
4. **Organization Unit Scope**: Use OUs for broad sharing within trusted boundaries

### Operational Guidelines

1. **Naming Conventions**: Use clear, descriptive names for shared resources
2. **Documentation**: Maintain records of what is shared and why
3. **Monitoring**: Enable CloudTrail for RAM API calls
4. **Regular Audits**: Review shares periodically for continued necessity

### Cost Optimization

- RAM sharing itself is free
- Shared resources incur costs in the account that creates them
- Consider centralized networking accounts for cost allocation

## Troubleshooting

### Common Issues

1. **Share Creation Failures**
   - Verify AWS Organizations is enabled
   - Check that accounts are in the same organization
   - Ensure RAM is enabled for the organization

2. **Provider Configuration**
   - Confirm org_management provider has correct permissions
   - Verify AWS profiles are correctly configured
   - Check credential chain and authentication

3. **Resource Access Issues**
   - Shared resources may take a few minutes to propagate
   - Verify principal associations are ASSOCIATED
   - Check that target accounts have accepted the share

## Requirements

- AWS Organizations must be configured
- RAM must be enabled for the organization
- For `enable_org_sharing = true`, the org_management provider must have permissions to manage RAM in the AWS Organizations management account
- Target accounts must be in the same AWS Organization
- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., sdlc, stage, prod) | string | n/a | yes |
| subnet_arns | List of subnet ARNs to share | list(string) | n/a | yes |
| enable_org_sharing | Enable RAM sharing with AWS Organizations | bool | true | no |
| share_with_accounts | List of AWS account IDs to share with | list(string) | [] | no |
| share_with_org_unit | Whether to share with an organization unit | bool | false | no |
| org_unit_arn | ARN of the organization unit to share with | string | null | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_share_id | ID of the RAM resource share |
| resource_share_arn | ARN of the RAM resource share |
| resource_share_status | Status of the RAM resource share |
| shared_subnet_arns | List of subnet ARNs that are shared |
| shared_with_accounts | List of account IDs the resources are shared with |
| shared_with_org_unit | Organization unit ARN the resources are shared with |
| org_sharing_enabled | Whether RAM sharing with AWS Organizations is enabled |
