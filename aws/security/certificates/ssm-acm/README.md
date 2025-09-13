# AWS ACM Certificate Import Module

This Terraform module imports SSL/TLS certificates from AWS Systems Manager (SSM) Parameter Store into AWS Certificate Manager (ACM), with support for **in-place updates that preserve certificate ARNs**.

## Features

- **In-Place Certificate Updates**: Preserves certificate ARNs during updates (configurable)
- **Cross-Account SSM Access**: Fetches certificates from centralized SSM in secops account
- **Multi-Region Support**: Deploy certificates to any AWS region
- **CloudFront Integration**: Optional CloudFront certificate deployment in us-east-1
- **Automated Monitoring**: EventBridge rules and SNS alerts for expiry notifications
- **Version Tracking**: Tracks certificate versions for audit purposes

## Certificate Update Behaviors

### In-Place Update (Default - Preserves ARN)

When `force_new_certificate_arn = false` (default):
- Certificate content is updated without changing the ARN
- Associated resources (ALBs, CloudFront, etc.) continue to work without reconfiguration
- Zero downtime during certificate renewal
- **Recommended for production environments**

### Recreate (Forces New ARN)

When `force_new_certificate_arn = true`:
- Creates a new certificate with a new ARN
- Old certificate is deleted after new one is created
- Requires updating any hardcoded ARN references
- Use only when you explicitly need a new certificate resource

## Usage

### Basic Usage (In-Place Updates)

```hcl
module "certificates" {
  source = "../../../modules/aws/security/certificates/ssm-acm"

  aws_region  = "us-east-1"
  environment = "prod"
  
  # Default behavior: in-place updates preserve ARNs
  force_new_certificate_arn = false
  certificate_update_behavior = "in-place"
  
  common_tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
  
  # CloudFront certificate (only in us-east-1)
  deploy_cloudfront_cert = true
  
  # Alert configuration
  alert_email = "devops@example.com"
  
  providers = {
    aws        = aws
    aws.secops = aws.secops
  }
}
```

### Force Recreation (New ARN)

```hcl
module "certificates" {
  source = "../../../modules/aws/security/certificates/ssm-acm"

  aws_region  = "us-east-1"
  environment = "dev"
  
  # Force new ARN on certificate change
  force_new_certificate_arn = true
  certificate_update_behavior = "recreate"
  
  # ... other configuration
}
```

## SSM Parameter Structure

The module expects the following SSM parameters in the secops account:

| Parameter Path | Description | Encrypted |
|---------------|-------------|-----------|
| `/certificates/multi-domain/certificate` | Certificate body (PEM format) | No |
| `/certificates/multi-domain/private-key` | Private key (PEM format) | Yes |
| `/certificates/multi-domain/chain` | Certificate chain (PEM format) | No |
| `/certificates/multi-domain/expiry` | Expiry date (YYYY-MM-DD format) | No |
| `/certificates/multi-domain/certificate-version` | Version identifier (optional) | No |

## Certificate Update Process

### 1. Update SSM Parameters

```bash
# Update certificate in SSM (worx-secops account)
aws ssm put-parameter \
  --name /certificates/multi-domain/certificate \
  --value "$(cat new-cert.pem)" \
  --overwrite \
  --profile worx-secops

aws ssm put-parameter \
  --name /certificates/multi-domain/private-key \
  --value "$(cat new-key.pem)" \
  --type SecureString \
  --overwrite \
  --profile worx-secops

aws ssm put-parameter \
  --name /certificates/multi-domain/chain \
  --value "$(cat new-chain.pem)" \
  --overwrite \
  --profile worx-secops

# Update version for tracking
aws ssm put-parameter \
  --name /certificates/multi-domain/certificate-version \
  --value "v2.0.0-$(date +%Y%m%d)" \
  --overwrite \
  --profile worx-secops
```

### 2. Apply Terraform Changes

```bash
# Navigate to the certificate deployment directory
cd infrastructure/environments/prod/certificates

# Plan changes to verify in-place update
terraform plan

# Apply changes - certificate will be updated in-place
terraform apply
```

### 3. Verify Update

```bash
# Check certificate ARN (should be unchanged)
aws acm list-certificates --region us-east-1 \
  --query 'CertificateSummaryList[?contains(DomainName, `yourdomain`)]'

# Verify certificate details
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:region:account:certificate/id \
  --query 'Certificate.[DomainName,Status,Serial,NotAfter]'
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | - | yes |
| `environment` | Environment name (dev/staging/prod) | `string` | - | yes |
| `common_tags` | Tags to apply to all resources | `map(string)` | `{}` | no |
| `deploy_cloudfront_cert` | Deploy CloudFront certificate | `bool` | `false` | no |
| `alert_email` | Email for expiry notifications | `string` | `""` | no |
| `force_new_certificate_arn` | Force new ARN on update | `bool` | `false` | no |
| `certificate_update_behavior` | Update behavior (in-place/recreate) | `string` | `"in-place"` | no |
| `enable_certificate_versioning` | Track certificate versions | `bool` | `true` | no |
| `certificate_rotation_days` | Days before expiry to alert | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | ARN of the imported certificate |
| `certificate_domain` | Primary domain name |
| `certificate_expiry` | Certificate expiration date |
| `certificate_status` | Certificate validation status |

## Migration from create_before_destroy

If you're migrating from the old module version that used `create_before_destroy = true`:

1. **Backup Current State**
   ```bash
   terraform state pull > terraform.state.backup
   ```

2. **Update Module Configuration**
   ```hcl
   # Add to your module configuration
   force_new_certificate_arn = false
   certificate_update_behavior = "in-place"
   ```

3. **Apply Changes Carefully**
   ```bash
   # First run may still create new ARNs due to state transition
   terraform apply
   
   # Future updates will preserve ARNs
   ```

## Best Practices

1. **Production Environments**: Always use in-place updates (`force_new_certificate_arn = false`)
2. **Testing**: Test certificate updates in dev/staging before production
3. **Monitoring**: Enable SNS alerts for certificate expiry notifications
4. **Version Tracking**: Use certificate versioning for audit trails
5. **Automation**: Integrate with CI/CD for automated certificate updates

## Troubleshooting

### Certificate Not Updating

If certificate doesn't update despite SSM parameter changes:
1. Clear Terraform cache: `rm -rf .terraform*`
2. Re-initialize: `terraform init`
3. Force refresh: `terraform refresh`
4. Apply changes: `terraform apply`

### ARN Changed Unexpectedly

Check if `force_new_certificate_arn` is set to `false` in your configuration.

### Validation Errors

Ensure certificate, private key, and chain are in valid PEM format and match each other.

## License

Copyright (c) Adaptive Technology. All rights reserved.
SPDX-License-Identifier: Apache-2.0
