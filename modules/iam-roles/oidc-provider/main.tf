# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0.0"
    }
  }
}

# Fetch the TLS certificate for Terraform Cloud
# AWS will use the certificate to verify requests for dynamic credentials come from Terraform Cloud
#
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "tfc_certificate" {
  url = "https://${var.oidc_hostname}"
}

# Creates an OIDC provider and restrict it to Terraform Cloud
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = [var.oidc_audience]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

