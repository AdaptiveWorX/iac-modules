# Cloudflare Zero Trust Module

This module creates and configures a Cloudflare Zero Trust tunnel with the appropriate routes and access configurations.

## Features

- Creates a Cloudflare Zero Trust tunnel with a secure random secret
- Configures tunnel routes for specified networks
- Sets up ingress rules for the tunnel
- Enables WARP routing

## Usage

```hcl
module "cloudflare_zero_trust" {
  source = "../../modules/cloudflare/zero-trust"

  prefix                = "myproject"
  cloudflare_account_id = "your_cloudflare_account_id"
  
  routes = [
    {
      network = "10.0.0.0/16"
      comment = "Main VPC network"
    }
  ]
  
  ingress_rules = [
    {
      hostname = "app.example.com"
      path     = "/*"
      service  = "http://internal-service:8080"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| cloudflare | >4.0.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| prefix | Prefix to add to resource names | `string` | yes |
| cloudflare_account_id | Cloudflare account ID | `string` | yes |
| routes | List of network routes to add to the tunnel | `list(object)` | yes |
| ingress_rules | List of ingress rules for the tunnel | `list(object)` | yes |

## Outputs

| Name | Description |
|------|-------------|
| tunnel_id | The ID of the created Cloudflare tunnel |
| tunnel_name | The name of the created Cloudflare tunnel |
| tunnel_token | The token used to authenticate to the tunnel |

## License

Apache-2.0