# VPC Peering Module

This module manages cross-region VPC peering connections with automatic route creation and DNS resolution.

## Features

- Cross-region VPC peering connection creation
- Automatic peering acceptance in peer region
- Route table updates in both VPCs
- DNS resolution across peered VPCs
- Support for multiple peer connections
- Conditional deployment based on connectivity flags

## Usage

### Basic Cross-Region Peering

```hcl
module "vpc_peering" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-peering?ref=v1.0.0"
  
  providers = {
    aws      = aws
    aws.peer = aws.peer_region
  }
  
  environment    = "sdlc"
  current_region = "us-east-1"
  vpc_id         = module.vpc_core.vpc_id
  vpc_cidr       = module.vpc_core.vpc_cidr
  
  route_table_ids = concat(
    [module.vpc_routing.public_route_table_id],
    module.vpc_routing.private_route_table_ids,
    module.vpc_routing.data_route_table_ids
  )
  
  peer_configs = [
    {
      region          = "us-west-2"
      vpc_id          = "vpc-12345678"
      vpc_cidr        = "10.195.0.0/16"
      route_table_ids = ["rtb-abc123", "rtb-def456"]
    }
  ]
  
  tags = {
    Environment = "sdlc"
    Project     = "infrastructure"
  }
}
```

### Multiple Peer Connections

```hcl
module "vpc_peering" {
  source = "..."
  
  # ... other configuration ...
  
  peer_configs = [
    {
      region          = "us-west-2"
      vpc_id          = "vpc-west"
      vpc_cidr        = "10.195.0.0/16"
      route_table_ids = ["rtb-west1", "rtb-west2"]
    },
    {
      region          = "eu-west-1"
      vpc_id          = "vpc-eu"
      vpc_cidr        = "10.198.0.0/16"
      route_table_ids = ["rtb-eu1", "rtb-eu2"]
    }
  ]
}
```

### Conditional Deployment with Terragrunt

```hcl
# In sdlc/peering/terragrunt.hcl
locals {
  connectivity = include.envcommon.locals.connectivity_config["sdlc"]
  current_region = get_env("AWS_REGION", "")
  
  # Only create if cross-region is enabled AND this region has peers
  should_create = local.connectivity.enable_cross_region && 
                  contains(keys(local.connectivity.peering_regions), local.current_region)
  
  peer_regions = local.should_create ? 
    lookup(local.connectivity.peering_regions, local.current_region, []) : []
}

# Skip this configuration if not needed
skip = !local.should_create

inputs = {
  vpc_id = dependency.vpc_core.outputs.vpc_id
  # ... rest of configuration
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform/opentofu | >= 1.6.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| aws.peer | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., sdlc, stage, prod) | `string` | n/a | yes |
| current_region | Current AWS region | `string` | n/a | yes |
| vpc_id | ID of the VPC in the current region | `string` | n/a | yes |
| vpc_cidr | CIDR block of the VPC in the current region | `string` | n/a | yes |
| route_table_ids | List of route table IDs in the current VPC | `list(string)` | n/a | yes |
| peer_configs | List of peer VPC configurations | `list(object)` | `[]` | no |
| tags | Additional tags to apply to resources | `map(string)` | `{}` | no |

### peer_configs Object Structure

```hcl
{
  region          = string       # AWS region of peer VPC
  vpc_id          = string       # ID of peer VPC
  vpc_cidr        = string       # CIDR block of peer VPC
  route_table_ids = list(string) # Route table IDs in peer VPC
}
```

## Outputs

| Name | Description |
|------|-------------|
| peering_connection_ids | Map of VPC peering connection IDs |
| peering_connection_status | Map of VPC peering connection statuses |
| peering_routes | List of all routes created for peering |

## Important Notes

1. **Provider Configuration**: This module requires two AWS provider configurations:
   - Default provider for the current region
   - `aws.peer` provider for the peer region

2. **IAM Permissions**: Ensure proper cross-account/cross-region permissions for VPC peering:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:CreateVpcPeeringConnection",
           "ec2:AcceptVpcPeeringConnection",
           "ec2:DescribeVpcPeeringConnections",
           "ec2:DeleteVpcPeeringConnection",
           "ec2:CreateRoute",
           "ec2:DeleteRoute",
           "ec2:DescribeRouteTables",
           "ec2:DescribeVpcs"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

3. **Route Conflicts**: Ensure no CIDR overlap between peered VPCs

4. **DNS Resolution**: The module enables DNS resolution between peered VPCs

5. **Cost Considerations**:
   - VPC Peering: $0.01 per GB of data transfer
   - No hourly charges for peering connections

## Example Provider Configuration

```hcl
# In your Terragrunt configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.current_region}"
  profile = "${local.aws_profile}"
}

provider "aws" {
  alias   = "peer"
  region  = "${local.peer_region}"
  profile = "${local.aws_profile}"
}
EOF
}
```

## Troubleshooting

### Common Issues

1. **Peering connection stuck in "pending-acceptance"**
   - Ensure the peer provider is correctly configured
   - Check IAM permissions in both regions

2. **Routes not being created**
   - Verify route table IDs are correct
   - Check for CIDR conflicts
   - Ensure peering connection is active

3. **DNS resolution not working**
   - Verify DNS resolution is enabled on both sides
   - Check security group rules allow DNS traffic (port 53)

### Debug Commands

```bash
# List peering connections
aws ec2 describe-vpc-peering-connections --region us-east-1

# Check route tables
aws ec2 describe-route-tables --region us-east-1 \
  --filters "Name=route.vpc-peering-connection-id,Values=pcx-*"

# Verify DNS settings
aws ec2 describe-vpc-peering-connections --region us-east-1 \
  --vpc-peering-connection-ids pcx-12345678 \
  --query 'VpcPeeringConnections[0].RequesterVpcInfo.PeeringOptions'
```

## License

Apache-2.0
