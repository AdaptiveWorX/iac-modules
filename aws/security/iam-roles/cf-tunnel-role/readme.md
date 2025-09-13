# IAM Cloudflare Tunnel Role Module

This module creates IAM roles required for ECS tasks to run Cloudflare tunnels, with the necessary permissions to access tunnel tokens from SSM Parameter Store and write to CloudWatch logs.

## Features

- Creates an IAM execution role for ECS tasks running Cloudflare tunnels
- Configures permissions to access CloudWatch logs
- Grants access to specific SSM parameters containing tunnel tokens
- Attaches the standard ECS task execution role policy

## Usage

```hcl
module "cf_tunnel_role" {
  source = "../../modules/iam/cf-tunnel-role"

  prefix           = "myproject"
  tunnel_token_arn = "arn:aws:ssm:region:account:parameter/myproject-cf-tunnel-token"
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
| tunnel_token_arn | ARN of the SSM parameter containing the tunnel token | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| execution_role_arn | ARN of the IAM execution role for the Cloudflare tunnel ECS task |
| execution_role_name | Name of the IAM execution role for the Cloudflare tunnel ECS task |

## License

MPL-2.0 