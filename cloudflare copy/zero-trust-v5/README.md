# Cloudflare Zero Trust Module (v5 Provider)

This module creates and configures a Cloudflare Zero Trust tunnel with the appropriate routes and access configurations, compatible with Cloudflare provider version 5.x and above.

## Features

- Creates a Cloudflare Zero Trust tunnel with a secure random secret
- Configures tunnel routes for specified networks with conditional management
- Sets up ingress rules for the tunnel
- Supports route conflict prevention across multiple tunnels
- Compatible with Cloudflare provider 5.x+

## Provider Requirements

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}
```

## Usage

```hcl
module "cloudflare_zero_trust" {
  source = "../../modules/cloudflare/zero-trust-v5"

  cloudflare_account_id = var.cloudflare_account_id
  prefix                = "prod"
  organization          = var.organization
  
  routes = [
    {
      network = "10.0.0.0/16"
      comment = "Main VPC network"
    },
    {
      network = "169.254.169.253/32"
      comment = "AWS DNS"
    }
  ]
  
  # Optional: Control which routes this tunnel manages
  # Useful to prevent duplicate route conflicts across multiple tunnels
  manage_routes = {
    "10.0.0.0/16"         = true   # This tunnel manages this route
    "169.254.169.253/32"  = false  # Another tunnel manages this route
  }
  
  ingress_rules = [
    {
      hostname = "app.example.com"
      path     = "/*"
      service  = "http://internal-service:8080"
    },
    {
      service = "http_status:404"  # Catch-all rule
    }
  ]
  
  config_src = "cloudflare"  # or "local" for local configuration
}
```

## Migrating from Provider 4.x

### Key Changes:
1. **Resource naming**: `cloudflare_zero_trust_tunnel_route` → `cloudflare_zero_trust_tunnel_cloudflared_route`
2. **Parameter changes**: `secret` → `tunnel_secret`
3. **New parameter**: `config_src` (required)
4. **Configuration format**: HCL blocks → JSON-style configuration

### Migration Steps:
1. Update provider version to `>= 5.0.0`
2. Change module source to `zero-trust-v5`
3. Add `config_src = "cloudflare"` to module parameters
4. Apply changes (tunnels may be recreated)

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `cloudflare_account_id` | Cloudflare account ID | `string` | yes | - |
| `prefix` | Prefix for resource names | `string` | yes | - |
| `organization` | Terraform Cloud organization name | `string` | yes | - |
| `routes` | List of network routes to add to the tunnel | `list(object({network=string, comment=string}))` | yes | - |
| `ingress_rules` | List of ingress rules for the tunnel | `list(object({hostname=optional(string), path=optional(string), service=string}))` | yes | - |
| `tunnel_secret` | Secret for the tunnel (auto-generated if not provided) | `string` | no | `""` |
| `config_src` | Configuration source: 'local' or 'cloudflare' | `string` | no | `"cloudflare"` |
| `manage_routes` | Map of routes to boolean values indicating management | `map(bool)` | no | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `tunnel_id` | The ID of the created Cloudflare tunnel |
| `tunnel_name` | The name of the created Cloudflare tunnel |
| `tunnel_cname` | The CNAME of the Cloudflare tunnel |
| `tunnel_token` | The token used to authenticate to the tunnel |

## Route Management

When deploying multiple tunnels that need access to the same networks (e.g., AWS DNS), use the `manage_routes` parameter to prevent duplicate route creation errors:

```hcl
# Production tunnel - manages shared routes
module "prod_tunnel" {
  source = "../../modules/cloudflare/zero-trust-v5"
  
  routes = [
    { network = "10.0.0.0/16", comment = "Prod VPC" },
    { network = "169.254.169.253/32", comment = "AWS DNS" }
  ]
  
  manage_routes = {
    "10.0.0.0/16"        = true
    "169.254.169.253/32" = true  # Prod manages the DNS route
  }
}

# SDLC tunnel - doesn't manage shared routes
module "sdlc_tunnel" {
  source = "../../modules/cloudflare/zero-trust-v5"
  
  routes = [
    { network = "10.1.0.0/16", comment = "SDLC VPC" },
    { network = "169.254.169.253/32", comment = "AWS DNS" }
  ]
  
  manage_routes = {
    "10.1.0.0/16"        = true
    "169.254.169.253/32" = false  # Don't manage - prod tunnel handles this
  }
}
```

## License

Apache-2.0
