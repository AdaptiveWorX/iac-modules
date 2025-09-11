# TFC Roles Module

This module creates IAM roles for Terraform Cloud (TFC) workspaces with optional cross-account access from the SecOps account. It supports both OIDC authentication for direct TFC access and cross-account role assumption for centralized management through the SecOps account.

## Features

- OIDC-based authentication for Terraform Cloud workspaces
- Optional cross-account access from SecOps account
- Flexible policy attachment through policy files
- Consistent tagging with customization support
- Project and workspace-based access control

## Policy Management

### Policy Types

1. **TFC Policies** (`*-tfc-policy`)
   - Direct access policies for Terraform Cloud
   - Named using pattern: `{policy-name}-tfc-policy`
   - Attached to the primary TFC role
   - Scoped to specific account resources

2. **Cross-Account Policies** (`*-tfc-xa-policy`)
   - Policies for cross-account access
   - Named using pattern: `{policy-name}-tfc-xa-policy`
   - Attached to cross-account roles
   - Enables SecOps management

### Policy Structure

Policies should follow these guidelines:
1. Use resource-level permissions where possible
2. Include appropriate condition blocks
3. Follow least-privilege principle
4. Use resource tags for access control

Example policy structure:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [...],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-west-2",
          "aws:ResourceTag/Account": "account-name"
        }
      }
    }
  ]
}
```

## Role Types

### Primary TFC Role
- Name: `{account-name}-tfc-role`
- Purpose: Direct Terraform Cloud access
- Authentication: OIDC
- Policies: Account-specific permissions

### Cross-Account Role
- Name: `{account-name}-tfc-xa-role`
- Purpose: SecOps management access
- Authentication: Role assumption
- Policies: Cross-account permissions

## Usage

### Basic Usage (OIDC Only)

```hcl
module "tfc_prod_app_role" {
  source = "../../modules/iam/tfc-roles"

  aws_account_name  = "prod-app"
  oidc_provider_arn = module.prod_app_oidc_provider.oidc_provider.arn
  oidc_provider_url = module.prod_app_oidc_provider.oidc_provider.url
  oidc_audience     = "aws.workload.identity"
  organization      = "adaptive"
  project          = "PROD"
  workspace        = "*"
  policy_files     = ["prod-app-account.json"]
}
```

### With Cross-Account Access

```hcl
module "tfc_prod_app_role" {
  source = "../../modules/iam/tfc-roles"

  aws_account_name     = "prod-app"
  oidc_provider_arn    = module.prod_app_oidc_provider.oidc_provider.arn
  oidc_provider_url    = module.prod_app_oidc_provider.oidc_provider.url
  oidc_audience        = "aws.workload.identity"
  organization        = "adaptive"
  project             = "PROD"
  workspace           = "*"
  policy_files        = ["prod-app-account.json"]
  enable_cross_account = true
  secops_account_id   = "123456789012"  # Replace with your SecOps account ID
}
```

## Requirements

- AWS Provider >= 5.42.0
- An OIDC provider configured in AWS IAM
- IAM policy files in the `policies/` directory

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_account_name | The name of the AWS account (e.g., secops, prod-app) | string | - | yes |
| oidc_provider_arn | The ARN of the OIDC provider | string | - | yes |
| oidc_provider_url | The URL of the OIDC provider | string | - | yes |
| oidc_audience | The audience value to verify in the OIDC token | string | - | yes |
| organization | The Terraform Cloud organization name | string | - | yes |
| project | The Terraform Cloud project name | string | - | yes |
| workspace | The Terraform Cloud workspace name pattern | string | - | yes |
| policy_files | List of policy files to attach to the role | list(string) | - | yes |
| enable_cross_account | Whether to enable cross-account access | bool | false | no |
| secops_account_id | The SecOps account ID (required if enable_cross_account is true) | string | "" | no |
| tags | Additional tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| tfc_role | The TFC role that can be assumed via OIDC |
| tfc_secops_xa_role | The SecOps cross-account role (if enabled) |

## Resource Naming

### Roles
- TFC Role: `{account-name}-tfc-role`
- Cross-Account Role: `{account-name}-tfc-xa-role`

### Policies
- TFC Policies: `{policy-name}-tfc-policy`
- Cross-Account Policies: `{policy-name}-tfc-xa-policy`

## Tags

All resources are tagged with:
- `Name`: Resource identifier
- `Account`: AWS account name
- `ManagedBy`: "terraform-cloud"
- `CrossAccess`: "true" (for cross-account resources)

## Security Best Practices

1. **OIDC Authentication**
   - Use specific workspace patterns
   - Validate audience claims
   - Enforce organization and project scope

2. **Cross-Account Access**
   - Enable only when needed
   - Use principal tag verification
   - Implement strict role assumption conditions

3. **Policy Management**
   - Follow least privilege principle
   - Use resource-level permissions
   - Implement tag-based access control
   - Regular policy review and updates

4. **Monitoring and Auditing**
   - Enable CloudTrail logging
   - Monitor role assumptions
   - Review policy attachments
   - Track cross-account access

## Architecture

This module supports Adaptive's AWS infrastructure where:

1. Each account has a TFC role for direct OIDC authentication
2. Child accounts (prod-app, prod-ucx, etc.) can optionally have a cross-account role
3. The SecOps account can assume these cross-account roles for centralized management
4. Access is controlled through:
   - OIDC conditions for direct TFC access
   - Project tag verification for cross-account access
   - Account-specific IAM policies

## Security Considerations

1. OIDC authentication is restricted to specific:
   - TFC organization
   - Project
   - Workspace pattern
   - Run phase

2. Cross-account access requires:
   - SecOps account ID
   - Project tag verification
   - Explicit enabling via `enable_cross_account`

3. All roles and policies follow least privilege principle through:
   - Account-specific policy files
   - Limited role assumption capabilities
   - Explicit resource tagging
