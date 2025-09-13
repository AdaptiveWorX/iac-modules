# Cloudflare Token Management Module

This module manages Cloudflare Account API tokens in AWS Secrets Manager with support for automatic rotation and expiration alerts.

## Features

- Store Cloudflare API tokens securely in AWS Secrets Manager
- Automatic token rotation support
- Expiration alerts via CloudWatch
- IAM policies for secure access
- Optional Lambda-based automatic rotation
- Support for multiple tokens with different purposes

## Usage

### Basic Usage

```hcl
module "cloudflare_tokens" {
  source = "../../modules/cloudflare/token-management"

  tokens = {
    zerotrust_prod = {
      token_value = var.cf_zerotrust_prod_token  # Store in tfvars or env var
      description = "Cloudflare Zero Trust API Token for Production"
      purpose     = "zero-trust-management"
      environment = "production"
    }
    dns_prod = {
      token_value = var.cf_dns_prod_token
      description = "Cloudflare DNS API Token for Production"
      purpose     = "dns-management"
      environment = "production"
    }
    readonly_ci = {
      token_value = var.cf_readonly_token
      description = "Read-only token for CI/CD validation"
      purpose     = "ci-validation"
      environment = "all"
    }
  }

  cloudflare_account_id = var.cloudflare_account_id
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With Automatic Rotation

```hcl
module "cloudflare_tokens" {
  source = "../../modules/cloudflare/token-management"

  tokens = {
    zerotrust_prod = {
      token_value = var.cf_zerotrust_prod_token
      description = "Cloudflare Zero Trust API Token for Production"
      purpose     = "zero-trust-management"
      environment = "production"
    }
  }

  cloudflare_account_id = var.cloudflare_account_id
  
  # Enable rotation
  enable_rotation           = true
  rotation_days            = 90
  enable_automatic_rotation = true
  rotation_check_days      = 7
  
  # Enable alerts
  enable_expiration_alerts = true
  alert_days_before_expiry = 14
  sns_topic_arn           = aws_sns_topic.alerts.arn
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Granting Access to Tokens

```hcl
# Attach read policy to a role
resource "aws_iam_role_policy_attachment" "read_tokens" {
  role       = aws_iam_role.app_role.name
  policy_arn = module.cloudflare_tokens.read_policy_arn
}

# Or for GitHub Actions OIDC role
resource "aws_iam_role_policy_attachment" "github_read_tokens" {
  role       = aws_iam_role.github_actions.name
  policy_arn = module.cloudflare_tokens.read_policy_arn
}
```

## Retrieving Tokens

### From AWS CLI

```bash
# Get token value
aws secretsmanager get-secret-value \
  --secret-id cloudflare/api-token/zerotrust-prod \
  --query SecretString \
  --output text
```

### From Terraform

```hcl
data "aws_secretsmanager_secret_version" "cf_token" {
  secret_id = module.cloudflare_tokens.secret_arns["zerotrust_prod"]
}

provider "cloudflare" {
  api_token = data.aws_secretsmanager_secret_version.cf_token.secret_string
}
```

### From GitHub Actions

```yaml
- name: Retrieve Cloudflare Token
  id: cf-token
  run: |
    TOKEN=$(aws secretsmanager get-secret-value \
      --secret-id cloudflare/api-token/zerotrust-prod \
      --query SecretString \
      --output text)
    echo "::add-mask::$TOKEN"
    echo "token=$TOKEN" >> $GITHUB_OUTPUT

- name: Use Token
  env:
    CLOUDFLARE_API_TOKEN: ${{ steps.cf-token.outputs.token }}
  run: |
    terraform apply
```

## Token Rotation

### Manual Rotation

1. Create new token in Cloudflare dashboard
2. Update in Secrets Manager:
   ```bash
   aws secretsmanager update-secret \
     --secret-id cloudflare/api-token/zerotrust-prod \
     --secret-string "new-token-value"
   ```
3. Verify new token works
4. Revoke old token in Cloudflare

### Automatic Rotation

When `enable_automatic_rotation` is true, the module creates a Lambda function that:
- Checks token expiration dates
- Sends alerts before expiration
- Can be extended to automatically create new tokens via Cloudflare API

## Security Best Practices

1. **Use Account API Tokens**: Never use User API tokens for automation
2. **Principle of Least Privilege**: Each token should have minimal required permissions
3. **Set Expiration Dates**: Configure tokens to expire (90 days for production)
4. **IP Restrictions**: Add IP allowlists in Cloudflare
5. **Audit Regularly**: Review token usage in Cloudflare Analytics
6. **Rotate Regularly**: Follow rotation schedule (90/180/365 days)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tokens | Map of tokens to manage | `map(object)` | n/a | yes |
| token_prefix | Prefix for secret names | `string` | `""` | no |
| cloudflare_account_id | Cloudflare account ID | `string` | `""` | no |
| enable_rotation | Enable rotation rules | `bool` | `false` | no |
| rotation_days | Days between rotations | `number` | `90` | no |
| rotation_check_days | Days between rotation checks | `number` | `7` | no |
| enable_automatic_rotation | Enable Lambda rotation | `bool` | `false` | no |
| enable_expiration_alerts | Enable expiration alerts | `bool` | `true` | no |
| alert_days_before_expiry | Days before expiry to alert | `number` | `14` | no |
| sns_topic_arn | SNS topic for alerts | `string` | `""` | no |
| tags | Tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arns | Map of secret ARNs |
| secret_names | Map of secret names |
| read_policy_arn | ARN of read policy |
| manage_policy_arn | ARN of manage policy |
| lambda_function_arn | ARN of rotation Lambda |
| lambda_role_arn | ARN of Lambda role |

## Token Types and Permissions

### Zero Trust Management
```yaml
Permissions:
  - Account | Cloudflare Tunnel:Edit
  - Account | Access: Organizations, Identity Providers:Edit
  - Account | Access: Service Tokens:Edit
```

### DNS Management
```yaml
Permissions:
  - Zone | Zone:Read
  - Zone | DNS:Edit
Zone Resources:
  - Include | Specific zones
```

### Read-Only CI/CD
```yaml
Permissions:
  - Account | Cloudflare Tunnel:Read
  - Zone | Zone:Read
  - Zone | DNS:Read
```

## Troubleshooting

### Token Not Found
```bash
# List all secrets
aws secretsmanager list-secrets \
  --filters Key=name,Values=cloudflare/

# Check secret exists
aws secretsmanager describe-secret \
  --secret-id cloudflare/api-token/zerotrust-prod
```

### Permission Denied
```bash
# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns arn:aws:secretsmanager:*:*:secret:cloudflare/*
```

### Token Invalid
```bash
# Verify token with Cloudflare
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

## License

Apache-2.0
