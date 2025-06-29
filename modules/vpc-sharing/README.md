# VPC Sharing Module

This module manages AWS Resource Access Manager (RAM) shares for VPC resources.

## Features

- Share VPC subnets with specific AWS accounts
- Share VPC subnets with AWS Organization units
- Enable RAM sharing with AWS Organizations (requires management account permissions)

## Usage

```hcl
module "vpc_sharing" {
  source = "./modules/vpc-sharing"

  environment = "production"
  subnet_arns = [
    "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345",
    "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-67890"
  ]
  
  share_with_accounts = ["987654321098", "876543210987"]
  
  # Enable organization-wide sharing (requires org management permissions)
  enable_org_sharing = true
  
  # Optional: Configure providers
  providers = {
    aws              = aws
    aws.org_management = aws.org_management
  }
}
```

## Provider Configuration

This module supports two provider configurations:

1. **Default provider** - Used for creating RAM shares and associations
2. **org_management provider** - Used for enabling RAM sharing with AWS Organizations

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
  region = "us-east-1"
}

provider "aws" {
  alias   = "org_management"
  region  = "us-east-1"
  profile = "adaptive-master"  # Management account profile
}
EOF
}
```

## Requirements

- AWS Organizations must be configured
- For `enable_org_sharing = true`, the org_management provider must have permissions to manage RAM in the AWS Organizations management account
- Target accounts must be in the same AWS Organization

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| subnet_arns | List of subnet ARNs to share | list(string) | - | yes |
| enable_org_sharing | Enable RAM sharing with AWS Organizations | bool | false | no |
| share_with_accounts | List of AWS account IDs to share with | list(string) | [] | no |
| share_with_org_unit | Whether to share with an organization unit | bool | false | no |
| org_unit_arn | ARN of the organization unit to share with | string | null | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_share_id | The ID of the RAM resource share |
| resource_share_arn | The ARN of the RAM resource share |
| resource_share_status | The status of the RAM resource share |
| shared_subnet_arns | List of subnet ARNs that were shared |
| shared_with_accounts | List of account IDs the resources were shared with |
| org_sharing_enabled | Whether organization sharing is enabled |
