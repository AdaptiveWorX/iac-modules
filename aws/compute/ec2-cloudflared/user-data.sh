#!/bin/bash
# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

set -e

# Variables passed from Terraform
TUNNEL_TOKEN="${tunnel_token}"
REGION="${region}"
ENVIRONMENT="${environment}"

# Logging setup
LOG_FILE="/var/log/cloudflared-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "Starting Cloudflare tunnel setup at $(date)"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"

# Update system
echo "Updating system packages..."
sudo dnf update -y
sudo dnf install -y curl wget jq

# Install cloudflared
install_cloudflared() {
    echo "Installing cloudflared..."
    
    # Download and install cloudflared for ARM64
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.rpm -o /tmp/cloudflared.rpm
    sudo rpm -i /tmp/cloudflared.rpm
    
    # Verify installation
    if ! command -v cloudflared &> /dev/null; then
        echo "Error: cloudflared installation failed"
        exit 1
    fi
    
    echo "cloudflared installed successfully: $(cloudflared --version)"
}

# Configure cloudflared service
configure_cloudflared() {
    echo "Configuring cloudflared service..."
    
    # Retrieve tunnel token from SSM Parameter Store
    echo "Retrieving tunnel token from SSM..."
    TOKEN=$(aws ssm get-parameter \
        --name "$TUNNEL_TOKEN" \
        --with-decryption \
        --query 'Parameter.Value' \
        --output text \
        --region "$REGION" 2>/dev/null)
    
    if [ -z "$TOKEN" ]; then
        echo "Error: Failed to retrieve tunnel token from SSM"
        exit 1
    fi
    
    echo "Successfully retrieved tunnel token"
    
    # Install cloudflared as a service with the token
    sudo cloudflared service install $TOKEN
    
    # Start and enable the service
    sudo systemctl start cloudflared
    sudo systemctl enable cloudflared
    
    # Wait for service to stabilize
    sleep 10
    
    # Verify service is running
    if systemctl is-active --quiet cloudflared; then
        echo "cloudflared service is running successfully"
    else
        echo "Error: cloudflared service failed to start"
        systemctl status cloudflared
        exit 1
    fi
}

# Install and configure CloudWatch agent
configure_monitoring() {
    echo "Installing CloudWatch agent..."
    
    # Download CloudWatch agent for ARM64
    wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/arm64/latest/amazon-cloudwatch-agent.rpm -O /tmp/cloudwatch-agent.rpm
    sudo rpm -U /tmp/cloudwatch-agent.rpm
    
    # Create CloudWatch agent configuration
    cat > /tmp/cloudwatch-config.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloudflared-setup.log",
            "log_group_name": "/aws/ec2/cloudflared/$ENVIRONMENT",
            "log_stream_name": "{instance_id}/setup",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/cloudflared/$ENVIRONMENT",
            "log_stream_name": "{instance_id}/system"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CloudflareTunnel",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "totalcpu": false,
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          {
            "name": "tcp_established",
            "rename": "TCP_CONNECTIONS",
            "unit": "Count"
          }
        ],
        "metrics_collection_interval": 60
      }
    },
    "aggregation_dimensions": [
      ["Environment"],
      ["Environment", "InstanceId"]
    ]
  }
}
EOF
    
    # Start CloudWatch agent with configuration
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c file:/tmp/cloudwatch-config.json
    
    echo "CloudWatch agent configured and started"
}

# Setup health check monitoring
setup_health_check() {
    echo "Setting up health check monitoring..."
    
    # Create health check script
    cat > /usr/local/bin/tunnel-health-check.sh <<'EOF'
#!/bin/bash
ENVIRONMENT="${environment}"
REGION="${region}"

# Check if cloudflared is running
if systemctl is-active --quiet cloudflared; then
    # Send success metric
    aws cloudwatch put-metric-data \
        --namespace "CloudflareTunnel" \
        --metric-name "TunnelHealth" \
        --value 1 \
        --dimensions Environment=$ENVIRONMENT,Region=$REGION \
        --region $REGION 2>/dev/null
    
    # Check tunnel connectivity
    if cloudflared tunnel info 2>/dev/null | grep -q "Connected"; then
        aws cloudwatch put-metric-data \
            --namespace "CloudflareTunnel" \
            --metric-name "TunnelConnectivity" \
            --value 1 \
            --dimensions Environment=$ENVIRONMENT,Region=$REGION \
            --region $REGION 2>/dev/null
    else
        aws cloudwatch put-metric-data \
            --namespace "CloudflareTunnel" \
            --metric-name "TunnelConnectivity" \
            --value 0 \
            --dimensions Environment=$ENVIRONMENT,Region=$REGION \
            --region $REGION 2>/dev/null
    fi
else
    # Send failure metric
    aws cloudwatch put-metric-data \
        --namespace "CloudflareTunnel" \
        --metric-name "TunnelHealth" \
        --value 0 \
        --dimensions Environment=$ENVIRONMENT,Region=$REGION \
        --region $REGION 2>/dev/null
    
    # Attempt to restart service
    sudo systemctl restart cloudflared
fi
EOF
    
    # Make script executable
    chmod +x /usr/local/bin/tunnel-health-check.sh
    
    # Add cron job for health check (every minute)
    echo "* * * * * /usr/local/bin/tunnel-health-check.sh" | sudo crontab -
    
    echo "Health check monitoring configured"
}

# Setup log rotation
setup_log_rotation() {
    echo "Configuring log rotation..."
    
    cat > /etc/logrotate.d/cloudflared <<EOF
/var/log/cloudflared*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    echo "Log rotation configured"
}

# Main execution
main() {
    echo "=== Starting Cloudflare Tunnel EC2 Setup ==="
    
    # Install cloudflared
    install_cloudflared
    
    # Configure cloudflared service
    configure_cloudflared
    
    # Setup monitoring
    configure_monitoring
    
    # Setup health checks
    setup_health_check
    
    # Configure log rotation
    setup_log_rotation
    
    # Send completion metric
    aws cloudwatch put-metric-data \
        --namespace "CloudflareTunnel" \
        --metric-name "SetupComplete" \
        --value 1 \
        --dimensions Environment=$ENVIRONMENT,Region=$REGION \
        --region $REGION 2>/dev/null
    
    echo "=== Cloudflare Tunnel EC2 Setup Complete ==="
    echo "Setup completed at $(date)"
}

# Execute main function
main

# Signal instance is ready (if using CloudFormation)
# Note: This is not used in Terraform deployments but kept for compatibility
if [ -f /opt/aws/bin/cfn-signal ]; then
    /opt/aws/bin/cfn-signal --success true --stack cloudflared-$ENVIRONMENT --resource AutoScalingGroup --region $REGION || true
fi
