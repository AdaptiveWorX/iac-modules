# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Launch Template for Cloudflared EC2 instances
resource "aws_launch_template" "cloudflared" {
  name_prefix   = "${var.environment}-cf-tunnel-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.cloudflared.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.cloudflared.id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name        = "${var.environment}-cf-tunnel"
      Environment = var.environment
      Service     = "cloudflare-tunnel"
      ManagedBy   = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name        = "${var.environment}-cf-tunnel-volume"
      Environment = var.environment
      Service     = "cloudflare-tunnel"
    })
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    tunnel_token = var.tunnel_token_parameter
    region       = var.aws_region
    environment  = var.environment
  }))

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for high availability
resource "aws_autoscaling_group" "cloudflared" {
  name_prefix               = "${var.environment}-cf-tunnel-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_cooldown          = 300

  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.cloudflared.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-cf-tunnel"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "cloudflare-tunnel"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy for CPU utilization
resource "aws_autoscaling_policy" "cpu_target" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.environment}-cf-tunnel-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.cloudflared.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Auto Recovery for failed instances
resource "aws_autoscaling_lifecycle_hook" "cloudflared_startup" {
  count = var.enable_auto_recovery ? 1 : 0

  name                   = "${var.environment}-cf-tunnel-startup"
  autoscaling_group_name = aws_autoscaling_group.cloudflared.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"

  notification_metadata = jsonencode({
    environment = var.environment
    service     = "cloudflare-tunnel"
  })
}
