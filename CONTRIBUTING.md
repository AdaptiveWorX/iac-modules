# Contributing to AdaptiveWorX IAC Modules

Thank you for your interest in contributing to the AdaptiveWorX Infrastructure as Code modules! This document provides guidelines and instructions for contributing to this repository.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- **Be respectful**: Treat everyone with respect and consideration
- **Be collaborative**: Work together to solve problems
- **Be inclusive**: Welcome diverse perspectives and experiences
- **Be professional**: Maintain professional communication

## 🚀 Getting Started

### Prerequisites

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/iac-modules.git
   cd iac-modules
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/AdaptiveWorX/iac-modules.git
   ```

### Development Environment

Required tools:
- OpenTofu 1.6+ or Terraform 1.5+
- AWS CLI (for testing AWS modules)
- Pre-commit hooks (recommended)
- tflint (for linting)
- tfsec or checkov (for security scanning)

Setup pre-commit hooks:
```bash
pip install pre-commit
pre-commit install
```

## 📝 How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Bug Fixes**: Fix issues in existing modules
2. **New Features**: Add functionality to existing modules
3. **New Modules**: Create entirely new modules
4. **Documentation**: Improve or add documentation
5. **Examples**: Add usage examples
6. **Tests**: Add or improve tests

### Contribution Process

1. **Check existing issues**: Look for related issues or discussions
2. **Create an issue**: Describe what you want to contribute
3. **Fork and branch**: Create a feature branch from `main`
4. **Make changes**: Implement your contribution
5. **Test thoroughly**: Ensure all tests pass
6. **Submit PR**: Create a pull request with a clear description

## 🔧 Development Guidelines

### Module Structure

Each module should follow this structure:
```
modules/category/module-name/
├── README.md           # Comprehensive documentation
├── main.tf            # Main resource definitions
├── variables.tf       # Input variable definitions
├── outputs.tf         # Output definitions
├── versions.tf        # Provider and version requirements
├── examples/          # Usage examples
│   └── basic/
│       ├── main.tf
│       └── README.md
└── tests/             # Test configurations
    └── basic_test.go
```

### Coding Standards

#### Terraform/OpenTofu Style

1. **Formatting**: Use `terraform fmt` or `tofu fmt`
   ```bash
   tofu fmt -recursive modules/
   ```

2. **Naming Conventions**:
   - Resources: `snake_case`
   - Variables: `snake_case`
   - Outputs: `snake_case`
   - Locals: `snake_case`
   - Module names: `kebab-case`

3. **Variable Definitions**:
   ```hcl
   variable "instance_type" {
     description = "EC2 instance type"  # Required
     type        = string               # Required
     default     = "t3.micro"           # Optional
     
     validation {                       # Recommended
       condition     = contains(["t3.micro", "t3.small"], var.instance_type)
       error_message = "Instance type must be t3.micro or t3.small"
     }
   }
   ```

4. **Resource Tagging**:
   ```hcl
   locals {
     common_tags = {
       Module      = "vpc-foundation"
       ManagedBy   = "Terraform"
       Environment = var.environment
     }
   }
   
   resource "aws_vpc" "main" {
     # ... configuration
     tags = merge(local.common_tags, var.tags, {
       Name = "${var.environment}-vpc"
     })
   }
   ```

### Documentation Requirements

#### Module README

Every module must have a README.md with:

1. **Description**: What the module does
2. **Usage**: Basic example
3. **Requirements**: Provider versions, prerequisites
4. **Providers**: List of required providers
5. **Inputs**: Table of all variables
6. **Outputs**: Table of all outputs
7. **Resources**: List of resources created
8. **Examples**: Link to examples directory

Use terraform-docs to generate documentation:
```bash
terraform-docs markdown modules/vpc/foundation > modules/vpc/foundation/README.md
```

#### Inline Comments

Add comments for complex logic:
```hcl
# Calculate subnet CIDR blocks based on VPC CIDR and subnet count
# This ensures even distribution across availability zones
locals {
  subnet_cidrs = [
    for i in range(var.subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
}
```

### Testing Requirements

#### Local Testing

1. **Validate syntax**:
   ```bash
   tofu init -backend=false
   tofu validate
   ```

2. **Check formatting**:
   ```bash
   tofu fmt -check -recursive
   ```

3. **Security scanning**:
   ```bash
   tfsec modules/
   checkov -d modules/
   ```

4. **Linting**:
   ```bash
   tflint --init
   tflint modules/
   ```

#### Integration Testing

For complex modules, provide integration tests:
```go
// tests/vpc_test.go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Add assertions
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation**: Ensure README is current
2. **Add examples**: Provide usage examples
3. **Test your changes**: Run all tests locally
4. **Check backwards compatibility**: Ensure no breaking changes
5. **Update CHANGELOG**: Document your changes

### PR Guidelines

#### Title Format
```
[module-name] Brief description

Examples:
[vpc-foundation] Add IPv6 support
[iam-roles] Fix policy attachment issue
[docs] Update contribution guidelines
```

#### Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Syntax validated
- [ ] Security scanned
- [ ] Integration tested
- [ ] Documentation updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. **Automated checks**: CI/CD runs validation
2. **Code review**: Maintainers review code
3. **Testing**: Verification in test environment
4. **Approval**: Requires maintainer approval
5. **Merge**: Squash and merge to main

## 🏷️ Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** (x.0.0): Breaking changes
- **MINOR** (0.x.0): New features (backwards compatible)
- **PATCH** (0.0.x): Bug fixes

### Breaking Changes

If introducing breaking changes:

1. **Document clearly** in CHANGELOG
2. **Provide migration guide**
3. **Update major version**
4. **Consider deprecation period**

Example migration guide:
```markdown
## Migration from v1.x to v2.0

### Breaking Changes
- Variable `subnet_count` renamed to `subnet_per_az_count`
- Output `subnet_ids` split into `public_subnet_ids` and `private_subnet_ids`

### Migration Steps
1. Update variable references:
   ```hcl
   # Old
   subnet_count = 3
   
   # New
   subnet_per_az_count = 3
   ```

2. Update output references:
   ```hcl
   # Old
   subnets = module.vpc.subnet_ids
   
   # New
   public_subnets = module.vpc.public_subnet_ids
   private_subnets = module.vpc.private_subnet_ids
   ```
```

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, include:

1. **Module version**: Tag or commit hash
2. **Terraform/OpenTofu version**: Output of `terraform version`
3. **Configuration**: Minimal reproduction example
4. **Error message**: Full error output
5. **Expected behavior**: What should happen
6. **Actual behavior**: What actually happened

### Feature Requests

For feature requests, provide:

1. **Use case**: Why you need this feature
2. **Proposed solution**: How it might work
3. **Alternatives considered**: Other approaches
4. **Additional context**: Related issues or PRs

## 📋 Maintenance

### For Maintainers

#### Release Process

1. **Update CHANGELOG.md**:
   ```markdown
   ## [1.2.0] - 2025-01-10
   ### Added
   - IPv6 support for VPC module
   ### Fixed
   - NAT Gateway deployment issue
   ```

2. **Update module versions** if needed

3. **Create release tag**:
   ```bash
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

4. **Create GitHub release**: Include changelog

#### Module Deprecation

When deprecating a module:

1. Add deprecation notice to README
2. Log deprecation warnings
3. Provide migration path
4. Set removal timeline (minimum 3 months)

## 💡 Best Practices

### Do's

✅ **DO** follow existing patterns and conventions
✅ **DO** write clear, self-documenting code
✅ **DO** include comprehensive examples
✅ **DO** consider backwards compatibility
✅ **DO** test in multiple scenarios
✅ **DO** update documentation

### Don'ts

❌ **DON'T** include hardcoded values (use variables)
❌ **DON'T** commit sensitive data
❌ **DON'T** break existing functionality
❌ **DON'T** ignore CI/CD failures
❌ **DON'T** merge without reviews

## 📚 Resources

### Learning Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Module Registry](https://registry.terraform.io/browse/modules)

### Tools

- [terraform-docs](https://github.com/terraform-docs/terraform-docs)
- [tflint](https://github.com/terraform-linters/tflint)
- [tfsec](https://github.com/aquasecurity/tfsec)
- [checkov](https://github.com/bridgecrewio/checkov)
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)

## 🙏 Recognition

Contributors will be recognized in:
- CHANGELOG.md (for specific contributions)
- GitHub contributors page
- Release notes

## 📬 Contact

- **Issues**: [GitHub Issues](https://github.com/AdaptiveWorX/iac-modules/issues)
- **Discussions**: [GitHub Discussions](https://github.com/AdaptiveWorX/iac-modules/discussions)
- **Security**: Report security issues privately to security@adaptiveworx.com

Thank you for contributing to AdaptiveWorX IAC Modules! 🎉
