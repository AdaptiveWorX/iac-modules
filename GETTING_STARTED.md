# Getting Started with AdaptiveWorX IAC Modules

Welcome to the AdaptiveWorX Infrastructure as Code (IaC) modules repository! This guide will help you get started using these OpenTofu/Terraform modules in your infrastructure projects.

## 🚀 Quick Start

### Prerequisites

- OpenTofu 1.6+ or Terraform 1.5+
- AWS CLI configured with appropriate credentials
- Git 2.0+
- Node.js 14+ (for contributing and semantic versioning)
- (Optional) Terragrunt 0.50+ for enhanced workflow

### Basic Usage

1. **Reference modules directly in your Terraform configuration:**

```hcl
module "vpc_foundation" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"
  
  environment        = "development"
  vpc_cidr          = "10.0.0.0/16"
  region_code       = "use1"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = {
    Project = "MyProject"
    Owner   = "DevOps"
  }
}
```

2. **Using with Terragrunt (Recommended):**

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.0.0"
}

inputs = {
  environment        = "production"
  vpc_cidr          = "10.100.0.0/16"
  region_code       = "usw2"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
}
```

## 📦 Available Modules

### Core Infrastructure
- **vpc/foundation** - Base VPC with subnets, route tables, and gateways
- **vpc/security** - Security groups, NACLs, and flow logs
- **vpc/operations** - Monitoring, bastion hosts, and VPC endpoints

### Security & Compliance
- **certificates/ssm-acm** - Certificate management with ACM
- **certificates/ssm-store** - Secure certificate storage in SSM
- **ram-tagging** - Resource Access Manager tagging

### Container Services
- **ecs-cluster/cf-tunnel-cluster** - ECS cluster for Cloudflare tunnels
- **ecs-cluster/devops-cross-account** - Cross-account DevOps operations

### Identity & Access
- **iam-roles/oidc-provider** - OIDC provider configuration
- **iam-roles/tfc-roles** - Terraform Cloud roles
- **iam-roles/cross-account-rds-access** - Cross-account database access

### Cloudflare Integration
- **cloudflare/zero-trust** - Zero Trust network configuration
- **cloudflare/zero-trust-deployment** - Complete Zero Trust deployment
- **cloudflare/token-management** - API token management

## 🏗️ Module Architecture

### Three-Layer VPC Architecture

Our VPC modules follow a three-layer architecture pattern:

1. **Foundation Layer** (`vpc/foundation`)
   - VPC, subnets, route tables
   - Internet and NAT gateways
   - Basic networking components

2. **Security Layer** (`vpc/security`)
   - Network ACLs
   - Security groups
   - VPC flow logs
   - Security controls

3. **Operations Layer** (`vpc/operations`)
   - VPC endpoints
   - Monitoring infrastructure
   - Bastion hosts
   - Operational tools

Deploy in order: Foundation → Security → Operations

## 🔧 Configuration Examples

### Multi-Region VPC Setup

```hcl
# us-east-1
module "vpc_use1" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"
  
  environment = "production"
  vpc_cidr    = "10.0.0.0/16"
  region_code = "use1"
  # ... other configuration
}

# us-west-2
module "vpc_usw2" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"
  
  environment = "production"
  vpc_cidr    = "10.1.0.0/16"
  region_code = "usw2"
  # ... other configuration
}
```

### ECS Cluster with Cloudflare Tunnel

```hcl
module "cf_tunnel_cluster" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/ecs-cluster/cf-tunnel-cluster?ref=main"
  
  cluster_name       = "cloudflare-tunnel"
  vpc_id            = module.vpc_foundation.vpc_id
  subnet_ids        = module.vpc_foundation.private_subnet_ids
  tunnel_token_arn  = aws_ssm_parameter.tunnel_token.arn
  
  enable_container_insights = true
  log_retention_days       = 30
}
```

## 📚 Best Practices

### Version Pinning

Always pin to a specific version in production:

```hcl
# Good - Pinned to specific version
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.2.3"

# Acceptable for development - Following main branch
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"

# Bad - No version specified
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation"
```

### Environment Separation

Use different configurations for each environment:

```hcl
# development.tfvars
environment = "development"
vpc_cidr    = "10.0.0.0/16"
enable_nat_gateway = false

# production.tfvars
environment = "production"
vpc_cidr    = "10.100.0.0/16"
enable_nat_gateway = true
single_nat_gateway = false
```

### Tagging Strategy

Always include consistent tags:

```hcl
tags = {
  Environment = var.environment
  Project     = "MyProject"
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
  CostCenter  = "Engineering"
}
```

## 🔍 Module Discovery

### Finding the Right Module

1. **Browse the modules directory**: Check `/modules` for available components
2. **Read module READMEs**: Each module has detailed documentation
3. **Check examples**: Look for example configurations in module directories
4. **Review variables**: Check `variables.tf` for all available options

### Module Documentation

Each module includes:
- `README.md` - Detailed documentation and examples
- `variables.tf` - All input variables with descriptions
- `outputs.tf` - Available outputs
- `versions.tf` - Provider and Terraform version requirements

## 🚦 Testing Modules Locally

### Local Development Setup

1. Clone the repository:
```bash
git clone https://github.com/AdaptiveWorX/iac-modules.git
cd iac-modules
```

2. Test a module locally:
```hcl
module "test_vpc" {
  source = "../path/to/iac-modules/modules/vpc/foundation"
  # ... configuration
}
```

3. Validate your configuration:
```bash
terraform init
terraform validate
terraform plan
```

## 📖 Common Patterns

### Cross-Account Access

```hcl
module "cross_account_role" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/iam-roles/cross-account-rds-access?ref=main"
  
  trusted_account_id = "123456789012"
  rds_secret_arns   = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds-*"
  ]
}
```

### Zero Trust Network

```hcl
module "zero_trust" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/cloudflare/zero-trust-deployment?ref=main"
  
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_api_token  = var.cloudflare_api_token
  tunnel_name          = "production-tunnel"
  vpc_id               = module.vpc_foundation.vpc_id
  subnet_ids           = module.vpc_foundation.private_subnet_ids
}
```

## 🆘 Getting Help

### Resources

- **Module Documentation**: Each module's README file
- **Issues**: [GitHub Issues](https://github.com/AdaptiveWorX/iac-modules/issues)
- **Examples**: Check module directories for example configurations
- **Discussions**: [GitHub Discussions](https://github.com/AdaptiveWorX/iac-modules/discussions)

### Common Issues

**Module not found:**
- Ensure you're using the correct path: `//modules/<category>/<module-name>`
- Check that the ref (branch/tag) exists

**Version conflicts:**
- Check `versions.tf` in the module for requirements
- Ensure your Terraform/OpenTofu version is compatible

**Authentication issues:**
- This is a public repository - no authentication needed!
- If cloning fails, check your internet connection

## 🔄 Contributing & Versioning

### Semantic Versioning

This repository uses automated semantic versioning with [semantic-release](https://semantic-release.gitbook.io/):

- **Conventional commits** trigger automatic versioning
- **GitHub releases** created automatically
- **CHANGELOG.md** updated with each release
- **Git tags** created for each version

### Contributing Workflow

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/iac-modules.git
   cd iac-modules
   npm install  # Install semantic-release dependencies
   ```

2. **Use Conventional Commits**
   ```bash
   # Features (minor version bump)
   git commit -m "feat: Add VPC endpoint support"
   
   # Fixes (patch version bump)
   git commit -m "fix: Correct subnet CIDR calculation"
   
   # Breaking changes (major version bump)
   git commit -m "feat!: Restructure module inputs
   
   BREAKING CHANGE: vpc_cidr is now vpc_cidr_block"
   
   # No version bump
   git commit -m "docs: Update README"
   git commit -m "style: Format files"
   git commit -m "test: Add tests"
   ```

3. **Create Pull Request**
   - CI/CD validates modules
   - Security scanning runs
   - Merge triggers automatic versioning

### Version Promotion

For environments using these modules with [iac-aws](https://github.com/AdaptiveWorX/iac-aws):

```bash
# Test in SDLC (uses local modules)
cd iac-aws/worx-secops/vpc/sdlc/foundation
terragrunt apply

# Promote to Stage
cd iac-aws
./scripts/promote-version.sh stage vpc_foundation

# Promote to Production
./scripts/promote-version.sh prod vpc_foundation
```

## 🎯 Next Steps

1. **Choose a module** that fits your needs
2. **Review the module's README** for specific documentation
3. **Start with a simple configuration** and expand
4. **Test in a development environment** first
5. **Pin to specific versions** for production use

Welcome to the AdaptiveWorX IaC community! 🚀
