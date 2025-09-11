# IAC Modules

This repository contains reusable OpenTofu modules for AdaptiveWorX infrastructure.

## Repository Structure

```
modules/
├── vpc/                    # VPC and networking components
│   ├── foundation/         # Base VPC, subnets, gateways
│   ├── security/          # NACLs, security groups
│   └── operations/        # Flow logs, monitoring
├── certificates/          # Certificate management
│   ├── ssm-acm/          # SSM to ACM import
│   └── ssm-store/        # SSM parameter storage
├── cloudflare/           # Cloudflare integrations
│   ├── token-management/
│   ├── zero-trust/
│   └── zero-trust-deployment/
├── ecs-cluster/          # ECS cluster configurations
│   ├── cf-tunnel-cluster/
│   └── devops-cross-account/
├── iam-roles/            # IAM roles and policies
│   ├── cf-tunnel-role/
│   ├── cross-account-rds-access/
│   ├── oidc-provider/
│   └── tfc-roles/
├── ram-tagging/          # Resource Access Manager tagging
├── ssm/                  # Systems Manager configurations
│   └── cf-tunnel-token/
└── flow-logs-analysis/   # VPC flow logs analysis
```

## Module Versioning

We use semantic versioning (SemVer) for our modules:
- `v1.0.0` - Major version (breaking changes)
- `v1.1.0` - Minor version (new features, backwards compatible)
- `v1.1.1` - Patch version (bug fixes)

## Usage

Reference modules in your Terragrunt configuration:

```hcl
terraform {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"
}
```

Or for a specific version tag:

```hcl
terraform {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.0.0"
}
```

## Development Workflow

1. Create a feature branch: `feature/module-name-description`
2. Develop and test your module
3. Create a pull request
4. After review and merge, tag the release

## Testing

All modules should include:
- Example configurations in `examples/`
- Tests in `test/`
- Comprehensive README documentation

## Module Standards

Each module should contain:
- `main.tf` - Main configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `versions.tf` - Provider requirements
- `README.md` - Module documentation

## Contributing

1. Follow the [OpenTofu Best Practices](https://www.terraform-best-practices.com/)
2. Use consistent naming conventions
3. Document all variables and outputs
4. Include examples for common use cases
