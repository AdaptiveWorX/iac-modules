# SSM Cloudflare Tunnel Token Module

This module creates a secure SSM parameter to store a Cloudflare tunnel token, which can be safely referenced by other services requiring tunnel access.

## Features

- Creates a secure SSM parameter for storing Cloudflare tunnel tokens
- Uses the SecureString parameter type for encrypted storage
- Implements lifecycle configuration to prevent accidental token updates

## Usage

```hcl
module "cf_tunnel_token" {
  source = "../../modules/ssm/cf-tunnel-token"

  prefix       = "myproject"
  tunnel_token = var.sensitive_tunnel_token
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0.0 |
| aws | ~> 4.0.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| prefix | Prefix to add to resource names | `string` | yes |
| tunnel_token | The token used to authenticate to the Cloudflare tunnel | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| parameter_name | The name of the SSM parameter |
| parameter_arn | The ARN of the SSM parameter |
| parameter_version | The version of the SSM parameter |

## License

MPL-2.0 