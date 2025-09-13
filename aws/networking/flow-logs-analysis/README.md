# Flow Logs Analysis Module

This module is planned for future development to provide advanced VPC Flow Log analysis capabilities.

## Planned Features

- **Athena Integration**: SQL-based analysis of S3-stored flow logs
- **CloudWatch Insights**: Real-time querying of CloudWatch flow logs
- **Security Analysis**: Automated detection of suspicious traffic patterns
- **Cost Optimization**: Analysis of data transfer costs and optimization recommendations
- **Compliance Reporting**: Automated generation of compliance reports
- **Alerting**: Intelligent alerting based on traffic patterns

## Architecture (Planned)

The module will create:

- **Athena Database**: For querying S3 flow logs
- **Athena Workgroup**: For cost management and query execution
- **Glue Catalog**: For metadata management
- **CloudWatch Dashboards**: For visualization
- **Lambda Functions**: For automated analysis and alerting
- **SNS Topics**: For alert notifications

## Usage (Future)

```hcl
module "flow_logs_analysis" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/flow-logs-analysis?ref=v1.0.0"

  vpc_id      = module.vpc_core.vpc_id
  environment = "prod"
  
  # S3 bucket from vpc-monitoring module
  flow_logs_bucket = module.vpc_monitoring.flow_log_s3_bucket_arn
  
  # Analysis configuration
  enable_athena_analysis = true
  enable_cloudwatch_insights = true
  enable_security_analysis = true
  
  # Alerting configuration
  alert_email = "security@company.com"
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

## Status

🚧 **Under Development** - This module is planned for future implementation.

## Dependencies

- VPC Core module
- VPC Monitoring module (for flow log storage)

## Requirements

- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0

## License

Copyright (c) Adaptive Technology. All rights reserved.
Licensed under the Apache-2.0 License. 