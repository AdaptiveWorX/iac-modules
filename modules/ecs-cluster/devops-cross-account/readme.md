# SecOps ECS Fargate Cross-Account Module

This Terraform module creates an ECS Fargate cluster with associated resources for deploying containerized DevOps operations across multiple AWS accounts in the SecOps architecture. The module is specifically designed for cross-account operations in the SecOps shared VPC environment.

## Features

- Creates an ECS cluster with Fargate launch type
- Sets up CloudWatch logging with optional KMS encryption
- Creates IAM roles for task execution and application permissions
- Configures security groups with customizable egress rules
- Enables Container Insights monitoring (optional)
- Supports inline policies and managed policy attachments
- Aligns with the SecOps Shared VPC architecture
- Enables cross-account operations through proper IAM roles

## Module Structure

```
modules/
└── ecs/
    ├── secops-cross-account/      # This module
    │   ├── main.tf                # Main module resources
    │   ├── variables.tf           # Input variables
    │   ├── outputs.tf             # Output values
    │   └── README.md              # This file
    └── cf-tunnel-cluster/         # CloudFlare tunnel cluster module
```

## SecOps Architecture Integration

This module is designed to work with the SecOps Shared VPC architecture, where:

1. The SecOps account (123456789012) owns all VPCs  # Replace with your SecOps account ID
2. DevOps ECS clusters can be deployed in the SecOps account using either PROD-VPC or SDLC-VPC
3. VPC sharing allows multiple accounts to use VPCs owned by SecOps:
   - PROD-VPC (10.0.0.0/16) - Used by all production accounts
   - SDLC-VPC (10.1.0.0/16) - Used by all non-production accounts

The module enables ECS tasks to operate across these shared VPCs through proper IAM roles and network routing.

## Usage

```hcl
module "secops_ecs_cluster" {
  source = "../../modules/ecs/secops-cross-account"

  cluster_name            = "devops-cluster"
  vpc_id                  = data.aws_vpc.prod_vpc.id
  subnet_ids              = data.aws_subnets.private_subnets.ids
  enable_container_insights = true
  log_retention_days      = 30
  
  # Additional egress rules for cross-account access
  additional_egress_rules = {
    prod_rds_mssql = {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["10.0.128.0/20"]  # PROD RDS CIDR block
      description = "Allow MSSQL to PROD RDS subnets"
    },
    sdlc_rds_mssql = {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["10.1.128.0/20"]  # SDLC RDS CIDR block
      description = "Allow MSSQL to SDLC RDS subnets"
    }
  }

  # Cross-account access policies
  task_role_inline_policies = {
    cross_account_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = [
            "arn:aws:iam::762541305735:role/prod-rds-access-role",
            "arn:aws:iam::135477718604:role/sdlc-rds-access-role"
          ]
        }
      ]
    })
  }
  
  tags = {
    Environment = "PROD"
    Purpose     = "DevOps"
    Account     = "SecOps"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| vpc_id | VPC ID where ECS tasks will run | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where ECS tasks will run | `list(string)` | n/a | yes |
| enable_container_insights | Whether to enable CloudWatch Container Insights | `bool` | `true` | no |
| log_retention_days | Number of days to retain CloudWatch logs | `number` | `14` | no |
| kms_key_arn | ARN of the KMS key to use for encrypting ECS data. If not provided, logs won't be encrypted unless create_kms_key is true | `string` | `null` | no |
| create_kms_key | Whether to create a new KMS key if kms_key_arn is not provided | `bool` | `false` | no |
| additional_egress_rules | Additional egress rules for ECS tasks security group | `map(object)` | `{}` | no |
| task_role_inline_policies | Map of inline IAM policies to attach to the ECS task role | `map(string)` | `{}` | no |
| task_role_managed_policy_arns | List of managed IAM policy ARNs to attach to the ECS task role | `list(string)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the ECS cluster |
| cluster_arn | The ARN of the ECS cluster |
| cluster_name | The name of the ECS cluster |
| task_execution_role_arn | The ARN of the ECS task execution role |
| task_execution_role_name | The name of the ECS task execution role |
| task_role_arn | The ARN of the ECS task role |
| task_role_name | The name of the ECS task role |
| security_group_id | The ID of the security group for ECS tasks |
| log_group_name | The name of the CloudWatch log group for ECS tasks |

## Cross-Account Operations

The DevOps ECS cluster in the SecOps account is designed to perform operations across multiple AWS accounts:

1. **PROD-APP Account (762541305735)**:
   - Access to PROD MSSQL RDS instances
   - Backup database operations
   - Access to PROD S3 buckets for backup storage

2. **SDLC-APP Account (135477718604)**:
   - Access to SDLC MSSQL RDS instances
   - Restore database operations
   - Access to ECR repositories for container images

Proper IAM roles with cross-account trust relationships are set up to enable these operations with least privilege principles:

```hcl
# Example of cross-account IAM roles in target accounts

# In PROD-APP account (762541305735)
resource "aws_iam_role" "prod_rds_access_role" {
  name = "prod-rds-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/devops-cluster-task-role"  # Replace with your SecOps account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-value"
          }
        }
      }
    ]
  })
}

# In SDLC-APP account (135477718604)
resource "aws_iam_role" "sdlc_rds_access_role" {
  name = "sdlc-rds-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/devops-cluster-task-role"  # Replace with your SecOps account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-value"
          }
        }
      }
    ]
  })
}
```

## Task Definition Example for Cross-Account Operations

```hcl
resource "aws_ecs_task_definition" "rds_backup_task" {
  family                   = "rds-backup"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = module.secops_ecs_cluster.task_execution_role_arn
  task_role_arn            = module.secops_ecs_cluster.task_role_arn

  container_definitions = jsonencode([{
    name  = "rds-backup"
    image = "135477718604.dkr.ecr.us-west-2.amazonaws.com/dev-ops:rds-backup-latest"
    environment = [
      {
        name  = "PROD_ROLE_ARN",
        value = "arn:aws:iam::762541305735:role/prod-rds-access-role"
      },
      {
        name  = "SDLC_ROLE_ARN",
        value = "arn:aws:iam::135477718604:role/sdlc-rds-access-role"
      },
      {
        name  = "EXTERNAL_ID",
        value = "unique-external-id-value"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.secops_ecs_cluster.log_group_name
        "awslogs-region"        = "us-west-2"
        "awslogs-stream-prefix" = "rds-backup"
      }
    }
  }])
}

# EventBridge Rule (using CloudWatch Events resource type)
resource "aws_cloudwatch_event_rule" "daily_clone" {
  name                = "daily-rds-clone"
  description         = "Trigger RDS clone daily at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

# EventBridge Target (using CloudWatch Events resource type)
resource "aws_cloudwatch_event_target" "run_clone_task" {
  rule      = aws_cloudwatch_event_rule.daily_clone.name
  target_id = "RunCloneTask"
  arn       = module.secops_ecs_cluster.cluster_arn
  role_arn  = aws_iam_role.eventbridge_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.rds_backup_task.arn
    launch_type         = "FARGATE"
    
    network_configuration {
      subnets          = data.aws_subnets.private_subnets.ids
      security_groups  = [module.secops_ecs_cluster.security_group_id]
      assign_public_ip = false
    }
  }
}

## Security Considerations

- The module creates IAM roles with minimal permissions
- Log encryption is optional through KMS
- Security groups are created with no ingress by default 
- Cross-account access is implemented using the principle of least privilege
- External IDs are used for cross-account role assumption for additional security
- Network access is restricted to specific CIDR blocks and ports

## Network Security Recommendations

When implementing cross-account operations, consider these network security recommendations:

1. **Restrict Network Routes**:
   - Only route specific subnet CIDRs across VPC peering connections
   - For RDS operations, only route traffic between ECS subnets and RDS subnets

2. **Security Group Precision**:
   - Define specific security group rules with exact port ranges (e.g., 1433 for MSSQL)
   - Limit CIDR ranges to specific subnets rather than entire VPCs

3. **Traffic Flow Control**:
   - Implement one-way traffic flows where possible
   - Block return paths that are not necessary for the operation

## License

MPL-2.0
