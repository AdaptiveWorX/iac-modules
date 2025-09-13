# RAM Tagging Module

This module applies Name tags to shared VPC resources in recipient AWS accounts. When VPC resources are shared via AWS Resource Access Manager (RAM), the tags from the owner account are not visible in the recipient accounts. This module bridges that gap by applying the same Name tags to the shared resources.

## Purpose

When a VPC is shared from one AWS account (e.g., worx-secops) to another account (e.g., worx-dev) using AWS RAM:
- The shared resources (VPC, subnets, route tables, etc.) appear in the recipient account
- However, the tags from the owner account are NOT visible in the recipient account
- This makes it difficult to identify resources by their descriptive names

This module solves this problem by:
1. Automatically discovering shared VPC resources from the owner account (worx-secops)
2. Reading the original Name tags from the shared resources
3. Applying the same Name tags to all shared resources in the recipient account
4. Making the shared resources easily identifiable

## Architecture

```
┌─────────────────────┐         ┌─────────────────────┐
│   Owner Account     │         │  Recipient Account  │
│   (worx-secops)     │         │   (worx-dev)       │
├─────────────────────┤         ├─────────────────────┤
│                     │   RAM   │                     │
│  VPC Resources      │ ──────> │  Shared Resources   │
│  with Name Tags     │  Share  │  (no tags visible)  │
│                     │         │                     │
└─────────────────────┘         └──────────┬──────────┘
                                           │
                                           │ This Module
                                           ▼
                                ┌─────────────────────┐
                                │  RAM Tagging Module │
                                │  Applies Name Tags  │
                                └─────────────────────┘
```

## Usage

### Basic Example

```hcl
module "ram_tagging" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/ram-tagging?ref=v1.0.0"

  environment = "dev"
  region      = "us-east-1"
  vpc_name    = "dev-vpc"

  tags = {
    ManagedBy = "terraform"
    Purpose   = "RAM Resource Tagging"
  }
}
```

The module automatically:
- Finds the shared VPC by name
- Discovers all shared subnets, route tables, and other resources
- Reads the original Name tags from the owner account (worx-secops)
- Applies the same Name tags in the recipient account

### Terragrunt Configuration Example

See the deployment configurations in:
- `iac-aws/worx-dev/ram-tagging/terragrunt.hcl`
- `iac-aws/worx-staging/ram-tagging/terragrunt.hcl`
- `iac-aws/worx-prod/ram-tagging/terragrunt.hcl`

## Resources Tagged

This module automatically discovers and tags:

- **VPC**: Applies the Name tag to the shared VPC
- **Subnets**: Applies Name tags to all shared subnets
- **Route Tables**: Applies Name tags to all shared route tables
- **Internet Gateway**: Applies the Name tag to the IGW
- **DHCP Options**: Applies the Name tag to the DHCP Options Set

## Requirements

- OpenTofu >= 1.6.0
- AWS Provider ~> 6.0
- The recipient account must have accepted the RAM share
- The module must run with credentials for the recipient account

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| vpc_name | Name of the shared VPC to find and tag | string | n/a | yes |
| tags | Additional tags to apply | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| total_resources_tagged | Total number of resources tagged |
| tagged_resource_summary | Summary of resources that were tagged |
| tagging_complete | Indicates whether the tagging process is complete |
| vpc_id | ID of the tagged VPC |

## How It Works

1. **Discovery**: The module uses data sources to find the shared VPC by name, filtering for resources owned by the worx-secops account (730335555486).

2. **Resource Enumeration**: Once the VPC is found, the module discovers all associated resources (subnets, route tables, etc.) that have been shared.

3. **Tag Reading**: For each discovered resource, the module reads the original Name tag from the owner account.

4. **Tag Application**: The module creates `aws_ec2_tag` resources to apply the same Name tags in the recipient account.

## Best Practices

1. **Run After Sharing**: Deploy this module after the VPC has been shared and accepted
2. **Use Dependencies**: In Terragrunt, use dependencies to ensure proper ordering
3. **Separate State**: Keep this module's state separate from the VPC infrastructure
4. **Automation**: Include in CI/CD pipelines to ensure tags are always synchronized

## Troubleshooting

### Tags Not Appearing
- Ensure the RAM share has been accepted in the recipient account
- Verify the module is running with the correct AWS credentials (recipient account)
- Check that the VPC name matches exactly

### Permission Errors
- The IAM role/user needs `ec2:CreateTags` permission on the shared resources
- Ensure the recipient account has accepted the RAM share invitation

### Resources Not Found
- Verify the VPC name is correct
- Check that resources are actually shared via RAM
- Ensure you're running in the correct region
