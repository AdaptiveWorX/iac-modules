# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "oidc_provider" {
  value = {
    arn = aws_iam_openid_connect_provider.oidc_provider.arn
    url = aws_iam_openid_connect_provider.oidc_provider.url
  }
  description = "The ARN and URL of the OIDC provider created."
}

output "tls_certificate" {
  value = {
    url = data.tls_certificate.tfc_certificate.url
  }
  description = "The URL of the TLS certificate fetched."
  
}