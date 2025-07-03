# Certificate Storage

This directory is for storing SSL certificates, private keys, and other sensitive cryptographic material.

## IMPORTANT SECURITY NOTICE

**NEVER commit actual certificate files to version control!**

The following files are automatically ignored by git:
- `*.crt` - Certificate files
- `*.key` - Private key files
- `*.pem` - PEM format certificates/keys
- `*.ca-bundle` - Certificate authority bundles
- All other certificate formats

## How to Handle Certificates

1. **Store certificates securely** in AWS Secrets Manager or SSM Parameter Store
2. **Reference them in Terraform** using data sources:
   ```hcl
   data "aws_secretsmanager_secret_version" "cert" {
     secret_id = "my-certificate"
   }
   ```
3. **For local development**, place certificate files in this directory - they will be ignored by git
4. **For production**, always use a secure secret management service

## Certificate Files Previously in Git

Certificate files were previously committed to this repository. They have been removed from tracking.
If you need these certificates, they should be:
1. Regenerated if compromised
2. Stored in AWS Secrets Manager
3. Referenced via Terraform data sources
