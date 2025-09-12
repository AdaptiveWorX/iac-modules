# AdaptiveWorX Infrastructure as Code Modules

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-1.6%2B-purple)](https://opentofu.org)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-blue)](https://terraform.io)

Welcome to the AdaptiveWorX Infrastructure as Code (IaC) modules repository! This public repository contains reusable OpenTofu/Terraform modules for building secure, scalable cloud infrastructure on AWS.

## 📚 Documentation

- **[Getting Started Guide](GETTING_STARTED.md)** - Quick start guide and examples
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute to this project
- **[Security Policy](SECURITY.md)** - Security standards and vulnerability reporting
- **[Migration Guide](MIGRATION_TO_PUBLIC.md)** - Information about the public repository transition

## 🚀 Quick Start

```hcl
module "vpc" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.0.0"
  
  environment        = "production"
  vpc_cidr          = "10.0.0.0/16"
  region_code       = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
}
```

> **Note**: Always use versioned releases (e.g., `?ref=v1.0.0`) in production. See [Versioning](#-versioning) for details.

## 📦 Available Modules

### Network Infrastructure
| Module | Description | Status |
|--------|-------------|--------|
| `vpc/foundation` | Base VPC with subnets, route tables, and gateways | Production Ready |
| `vpc/security` | Security groups, NACLs, and VPC flow logs | Production Ready |
| `vpc/operations` | Monitoring, bastion hosts, and VPC endpoints | Production Ready |

### Compute Services
| Module | Description | Status |
|--------|-------------|--------|
| `lambda/data-processor` | Data processing Lambda functions | In Development |
| `ecs/web-api` | Web API service on ECS Fargate | In Development |

### Database Services
| Module | Description | Status |
|--------|-------------|--------|
| `rds/postgresql` | PostgreSQL RDS instances with read replicas | In Development |

### Security & Compliance
| Module | Description | Status |
|--------|-------------|--------|
| `certificates/ssm-acm` | Certificate management with ACM | Production Ready |
| `certificates/ssm-store` | Secure certificate storage in SSM | Production Ready |
| `ram-tagging` | Resource Access Manager tagging | Production Ready |

### Container Services
| Module | Description | Status |
|--------|-------------|--------|
| `ecs-cluster/cf-tunnel-cluster` | ECS cluster for Cloudflare tunnels | Production Ready |
| `ecs-cluster/devops-cross-account` | Cross-account DevOps operations | Production Ready |

### Identity & Access
| Module | Description | Status |
|--------|-------------|--------|
| `iam-roles/oidc-provider` | OIDC provider configuration | Production Ready |
| `iam-roles/tfc-roles` | Terraform Cloud roles | Production Ready |
| `iam-roles/cross-account-rds-access` | Cross-account database access | Production Ready |

### Cloudflare Integration
| Module | Description | Status |
|--------|-------------|--------|
| `cloudflare/zero-trust` | Zero Trust network configuration | Production Ready |
| `cloudflare/zero-trust-deployment` | Complete Zero Trust deployment | Production Ready |
| `cloudflare/token-management` | API token management | Production Ready |

### Operations & Monitoring
| Module | Description | Status |
|--------|-------------|--------|
| `flow-logs-analysis` | VPC flow logs analysis | Production Ready |
| `ssm/cf-tunnel-token` | CloudFlare tunnel token management | Production Ready |

## 🏗️ Architecture Patterns

### Three-Layer VPC Architecture

Our VPC modules follow a three-layer architecture pattern for enhanced security and separation of concerns:

```
Foundation Layer → Security Layer → Operations Layer
```

1. **Foundation**: Core networking (VPC, subnets, gateways)
2. **Security**: Access controls (NACLs, security groups, flow logs)
3. **Operations**: Operational tools (monitoring, endpoints, bastion)

## ⚡ Key Features

- **🔒 Security First**: All modules follow security best practices
- **🔄 Version Control**: Semantic versioning for stable deployments
- **📝 Well Documented**: Comprehensive documentation for each module
- **✅ Tested**: Integration tests and examples included
- **🌍 Multi-Region**: Support for multi-region deployments
- **🏢 Multi-Account**: Cross-account access patterns
- **☁️ Cloud Native**: Optimized for AWS services

## 📋 Requirements

- OpenTofu 1.6+ or Terraform 1.5+
- AWS CLI configured with appropriate credentials
- Git 2.0+
- (Optional) Terragrunt 0.50+ for enhanced workflow

## 🛠️ Module Development

### Standard Structure

Each module follows a consistent structure:

```
modules/category/module-name/
├── README.md           # Module documentation
├── main.tf            # Main configuration
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── versions.tf        # Provider requirements
├── examples/          # Usage examples
└── tests/            # Integration tests
```

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-module
   ```

2. **Develop Module**
   - Follow the standard structure
   - Include comprehensive documentation
   - Add usage examples

3. **Commit with Conventional Messages**
   ```bash
   git commit -m "feat: Add new RDS module"
   git commit -m "fix: Resolve security group issue"
   git commit -m "docs: Update VPC module README"
   ```

4. **Create Pull Request**
   - CI/CD runs validation
   - Security scanning (tfsec, checkov)
   - Documentation checks

5. **Automatic Versioning**
   - Merge to main triggers semantic-release
   - Version created based on commit messages
   - Changelog automatically updated

### Commit Convention

| Type | Version Bump | Description |
|------|--------------|-------------|
| `feat` | Minor (1.X.0) | New feature |
| `fix` | Patch (1.0.X) | Bug fix |
| `feat!` | Major (X.0.0) | Breaking change |
| `docs` | No bump | Documentation only |
| `style` | No bump | Code style changes |
| `refactor` | No bump | Code refactoring |
| `test` | No bump | Test changes |
| `chore` | No bump | Build/tool changes |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code standards
- Testing requirements
- Pull request process
- Security best practices

## 🔒 Security

Security is our top priority. Please review our [Security Policy](SECURITY.md) for:

- Security standards
- Vulnerability reporting
- Best practices
- Compliance information

**Never commit secrets or sensitive data!** Report security issues to security@adaptiveworx.com

## 📖 Examples

### Basic VPC Setup

```hcl
module "vpc" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.0.0"
  
  environment = "development"
  vpc_cidr    = "10.0.0.0/16"
  region_code = "use1"
  
  # ... additional configuration
}
```

### ECS Cluster with Cloudflare Tunnel

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/ecs-cluster/cf-tunnel-cluster?ref=v1.0.0"
  
  cluster_name = "cloudflare-tunnel"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  
  # ... additional configuration
}
```

More examples available in each module's `examples/` directory.

## 📈 Versioning

We use [Semantic Versioning](https://semver.org/) with automated releases:

- **MAJOR** version for incompatible changes (breaking changes)
- **MINOR** version for backwards-compatible features
- **PATCH** version for backwards-compatible fixes

### Automated Releases

This repository uses [semantic-release](https://semantic-release.gitbook.io/) for automated version management:

1. **Conventional commits** trigger automatic versioning
2. **GitHub releases** created automatically
3. **Changelog** updated with each release
4. **Git tags** created for each version

### Using Module Versions

```hcl
# Development - use main branch
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=main"

# Staging - use latest stable version
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.2.0"

# Production - pin to specific tested version
source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc/foundation?ref=v1.0.5"
```

**Always pin to specific versions in production!**

### Version Promotion

For environments using these modules:
1. Test new versions in development (DEV)
2. Promote to staging after validation
3. Deploy to production after staging verification

See the [iac-aws repository](https://github.com/AdaptiveWorX/iac-aws) for environment-specific version management.

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check module README files
- **Issues**: [GitHub Issues](https://github.com/AdaptiveWorX/iac-modules/issues)
- **Discussions**: [GitHub Discussions](https://github.com/AdaptiveWorX/iac-modules/discussions)
- **Security**: security@adaptiveworx.com

## 🌟 Acknowledgments

- OpenTofu community for the excellent IaC tooling
- AWS for comprehensive cloud services
- All contributors who help improve these modules

---

**Note**: This is a public repository. Do not commit any sensitive information, credentials, or proprietary data.
