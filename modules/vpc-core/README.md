# VPC Core Module

This module creates the foundational VPC infrastructure including the VPC itself, subnets, internet gateway, and egress-only internet gateway.

## Features

- Creates a VPC with customizable CIDR block
- Creates public, private, and data subnets across multiple availability zones
- Provisions Internet Gateway (IGW) for public subnet connectivity
- Provisions Egress-Only Internet Gateway (EIGW) for IPv6 outbound traffic
- Supports custom tags and naming conventions

## Usage

```hcl
module "vpc_core" {
  source = "git::git@github.com:AdaptiveWorX/iac-modules.git//modules/vpc-core?ref=v1.0.0"

  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  data_subnet_cidrs    = ["10.0.21.0/24", "10.0.22.0/24"]
  
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  tags = {
    Environment = "sdlc"
    Project     = "infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | CIDR block for the VPC | string | n/a | yes |
| public_subnet_cidrs | List of CIDR blocks for public subnets | list(string) | n/a | yes |
| private_subnet_cidrs | List of CIDR blocks for private subnets | list(string) | n/a | yes |
| data_subnet_cidrs | List of CIDR blocks for data subnets | list(string) | n/a | yes |
| availability_zones | List of availability zones | list(string) | n/a | yes |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | bool | true | no |
| enable_dns_support | Enable DNS support in the VPC | bool | true | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| data_subnet_ids | List of data subnet IDs |
| internet_gateway_id | ID of the Internet Gateway |
| egress_only_internet_gateway_id | ID of the Egress-Only Internet Gateway |

## Requirements

- OpenTofu >= 1.6.0
- AWS Provider ~> 5.0
