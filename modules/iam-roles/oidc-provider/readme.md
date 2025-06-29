# AWS OIDC Provider Module

This module creates an OpenID Connect (OIDC) identity provider in AWS IAM for Terraform Cloud workload identity federation. It establishes the trust relationship between AWS and Terraform Cloud, enabling secure authentication without static credentials.

## Features

- Creates an OIDC provider for Terraform Cloud
- Configures trust relationships with appropriate conditions
- Validates JWT tokens and claims
- Supports multiple AWS accounts
- Implements security best practices

## Usage

```hcl
module "tfc_oidc_provider" {
  source = "../../modules/iam/oidc-provider"

  oidc_hostname = "app.terraform.io"
  oidc_audience = "aws.workload.identity"
}
```

## Requirements

- AWS Provider >= 5.42.0
- AWS account with IAM permissions to create OIDC providers

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| oidc_hostname | The hostname of the OIDC provider (e.g., app.terraform.io) | string | - | yes |
| oidc_audience | The audience value to verify in the OIDC token | string | - | yes |
| tags | Additional tags to apply to the OIDC provider | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider | The OIDC provider object containing ARN and URL |

## Security Features

1. **Token Validation**
   - Validates issuer URL
   - Verifies audience claims
   - Enforces TLS certificate checks
   - Implements thumbprint verification

2. **Trust Relationship**
   - Configures secure trust policy
   - Enforces HTTPS communication
   - Validates client credentials
   - Implements token expiration

3. **Access Control**
   - Restricts to specific Terraform Cloud instances
   - Enforces audience validation
   - Implements role-based access
   - Supports resource-level permissions

## Architecture

This module is part of Adaptive's AWS infrastructure where:

1. Each AWS account has its own OIDC provider
2. The provider establishes trust with Terraform Cloud
3. Workspaces use this trust for authentication
4. No static credentials are required

## Best Practices

1. **Provider Configuration**
   - Use HTTPS for all communications
   - Implement proper thumbprint validation
   - Configure appropriate timeouts
   - Enable logging and monitoring

2. **Security**
   - Follow least privilege principle
   - Regularly rotate certificates
   - Monitor provider health
   - Review access patterns

3. **Maintenance**
   - Keep provider version updated
   - Monitor for security advisories
   - Regular configuration review
   - Update thumbprints as needed

## Related Modules

- [TFC Roles](../tfc-roles/README.md) - Creates IAM roles that trust this OIDC provider
- [TFC Workspaces](../../tfc/workspace/README.md) - Creates workspaces that use these OIDC providers 