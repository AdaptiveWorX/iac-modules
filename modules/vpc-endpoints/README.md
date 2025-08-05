# VPC Endpoints Module

This module manages VPC endpoints for AWS services, providing private connectivity to AWS services without requiring internet gateway access. It supports both gateway endpoints (free) and interface endpoints (paid).

## Features

- Creates S3 gateway endpoint (always enabled, free)
- Optional DynamoDB gateway endpoint (free)
- Supports multiple interface endpoints for various AWS services
- Automatic security group creation for interface endpoints
- Private DNS enabled for interface endpoints
- Comprehensive tagging support

## Usage

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-endpoints?ref=v1.0.0"

  vpc_id              = module.vpc_core.vpc_id
  vpc_cidr            = module.vpc_core.vpc_cidr
  region              = "us-east-1"
  environment         = "sdlc"
  route_table_ids     = concat(
    module.vpc_core.private_route_table_ids,
    module.vpc_core.data_route_table_ids
  )
  endpoint_subnet_ids = module.vpc_core.private_subnet_ids

  # Optional: Enable DynamoDB endpoint
  enable_dynamodb_endpoint = true

  # Optional: Enable interface endpoints (these cost money)
  interface_endpoints = [
    "ec2",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "kms",
    "secretsmanager"
  ]

  tags = {
    Environment = "sdlc"
    Project     = "infrastructure"
  }
}
```

## Gateway vs Interface Endpoints

### Gateway Endpoints (Free)
- **S3**: Always created, provides access to S3 without internet gateway
- **DynamoDB**: Optional, controlled by `enable_dynamodb_endpoint`
- Route-based: Uses route tables to direct traffic
- No additional charges

### Interface Endpoints (Paid)
- Created for services specified in `interface_endpoints` list
- DNS-based: Uses private DNS to resolve service endpoints
- Requires ENI in specified subnets
- Charges apply for endpoint hours and data processing

## Common Interface Endpoints

| Service | Endpoint Name | Use Case |
|---------|--------------|----------|
| EC2 | ec2 | EC2 API calls |
| Systems Manager | ssm | SSM agent connectivity |
| SSM Messages | ssmmessages | SSM session manager |
| EC2 Messages | ec2messages | SSM run command |
| KMS | kms | Encryption operations |
| Secrets Manager | secretsmanager | Secret retrieval |
| ECS | ecs | ECS agent connectivity |
| ECR API | ecr.api | Docker registry API |
| ECR DKR | ecr.dkr | Docker image pulls |
| CloudWatch Logs | logs | Log streaming |
| CloudWatch | monitoring | Metrics and alarms |
| SNS | sns | Notifications |
| SQS | sqs | Queue operations |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | VPC ID where endpoints will be created | string | n/a | yes |
| vpc_cidr | VPC CIDR block for security group rules | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| environment | Environment name (e.g., sdlc, stage, prod) | string | n/a | yes |
| route_table_ids | List of route table IDs for gateway endpoints | list(string) | n/a | yes |
| endpoint_subnet_ids | List of subnet IDs for interface endpoints (typically private subnets) | list(string) | [] | no |
| enable_dynamodb_endpoint | Enable DynamoDB gateway endpoint | bool | false | no |
| interface_endpoints | List of interface endpoints to create | list(string) | [] | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| s3_endpoint_id | ID of the S3 VPC endpoint |
| s3_endpoint_prefix_list_id | Prefix list ID of the S3 VPC endpoint for use in security groups |
| dynamodb_endpoint_id | ID of the DynamoDB VPC endpoint |
| dynamodb_endpoint_prefix_list_id | Prefix list ID of the DynamoDB VPC endpoint |
| interface_endpoint_ids | Map of interface endpoint service names to their IDs |
| interface_endpoint_dns_names | Map of interface endpoint service names to their DNS names |
| endpoints_security_group_id | Security group ID for interface endpoints |
| gateway_endpoints | List of gateway endpoints created |
| interface_endpoints_list | List of interface endpoints created |

## Security Considerations

- Interface endpoints are protected by a security group allowing HTTPS (443) from the VPC CIDR
- Gateway endpoints use route tables for access control
- Consider using endpoint policies for additional access restrictions
- Interface endpoints support private DNS, eliminating the need to update application configurations

## Cost Optimization

- Gateway endpoints (S3, DynamoDB) are free - use them whenever possible
- Interface endpoints incur hourly charges - only enable what you need
- Consider centralizing interface endpoints in a shared VPC for cost efficiency
- Monitor endpoint usage with CloudWatch metrics

## Requirements

- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0
