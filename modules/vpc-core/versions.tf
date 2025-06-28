terraform {
  required_version = ">= 1.10.0"  # OpenTofu 1.10.0 or later
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # Latest major version of AWS provider
    }
  }
}
