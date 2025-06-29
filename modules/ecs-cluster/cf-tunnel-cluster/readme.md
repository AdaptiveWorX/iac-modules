# ECS Cloudflare Tunnel Cluster Module

This module creates an ECS cluster and related resources to run Cloudflare tunnels in AWS Fargate, establishing secure connectivity between your AWS infrastructure and the Cloudflare network.

## Features

- Creates an ECS cluster with Fargate capacity providers
- Configures a Fargate task definition for running Cloudflare tunnel containers
- Sets up AWS Service Discovery for DNS resolution
- Creates CloudWatch log groups for container logs
- Configures appropriate security groups for the tunnel service
- Deploys an ECS service with the tunnel task definition

## Usage

```hcl
module "cf_tunnel_cluster" {
  source = "../../modules/ecs/cf-tunnel-cluster"

  prefix             = "myproject"
  vpc_id             = "vpc-12345"
  subnet_ids         = ["subnet-1", "subnet-2"]
  execution_role_arn = module.cf_tunnel_role.execution_role_arn
  tunnel_token_name  = module.cf_tunnel_token.parameter_name
  fargate_type       = "FARGATE_SPOT"
  cpu                = 256
  memory             = 512
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| prefix | Prefix to add to resource names | `string` | yes |
| vpc_id | VPC ID where ECS tasks will run | `string` | yes |
| subnet_ids | Subnet IDs where ECS tasks will run | `list(string)` | yes |
| execution_role_arn | ARN of the IAM execution role for the Cloudflare tunnel ECS task | `string` | yes |
| tunnel_token_name | Name of the SSM parameter containing the tunnel token | `string` | yes |
| fargate_type | Fargate capacity provider type (FARGATE or FARGATE_SPOT) | `string` | no |
| cpu | CPU units for the Fargate task (256, 512, 1024, etc.) | `number` | no |
| memory | Memory for the Fargate task in MB (512, 1024, 2048, etc.) | `number` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the created ECS cluster |
| cluster_arn | ARN of the created ECS cluster |
| service_name | Name of the created ECS service |
| service_discovery_namespace_id | ID of the created service discovery namespace |

## License

MPL-2.0 