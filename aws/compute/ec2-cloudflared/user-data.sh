# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

#!/bin/bash
# User data script for cloudflared EC2 instance
# This script installs and configures cloudflared on Amazon Linux 2023

set -e

# Variables passed from Terraform
ENVIRONMENT="${environment}"
TUNNEL_TOKEN_PARAM="${tunnel_token}"
TUNNEL_NAME="${tunnel_name}"
REGION="${region}"
CLOUDFLARED_VERSION="${cloudflared_version}"
LOG_GROUP="${log_group_name}"
TUNNEL_ROUTES='${tunnel_routes}'
METRICS_INTERVAL="${metrics_interval}"

# Logging setup
LOG_FILE="/var/log/cloudflared-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting cloudflared setup for environment: $ENVIRONMENT"

# Update system
log "Updating system packages..."
dnf update -y
dnf install -y amazon-cloudwatch-agent jq wget systemd-resolved

# Install AWS CLI v2 if not present
if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI v2..."
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install latest cloudflared
log "Installing cloudflared version $CLOUDFLARED_VERSION..."
ARCH="arm64"
wget -q "https://github.com/cloudflare/cloudflared/releases/download/$CLOUDFLARED_VERSION/cloudflared-linux-$ARCH" -O /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Create cloudflared user and directories
log "Creating cloudflared user and directories..."
useradd -r -s /bin/false cloudflared || true
mkdir -p /etc/cloudflared
mkdir -p /var/log/cloudflared
chown -R cloudflared:cloudflared /etc/cloudflared /var/log/cloudflared

# Get tunnel token from SSM Parameter Store
log "Retrieving tunnel token from SSM..."
if [ -n "$TUNNEL_TOKEN_PARAM" ]; then
    TUNNEL_TOKEN=$(aws ssm get-parameter \
        --name "$TUNNEL_TOKEN_PARAM" \
        --with-decryption \
        --region "$REGION" \
        --query 'Parameter.Value' \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$TUNNEL_TOKEN" ]; then
        log "ERROR: Failed to retrieve tunnel token from SSM parameter: $TUNNEL_TOKEN_PARAM"
        exit 1
    fi
else
    log "WARNING: No tunnel token parameter specified. Tunnel will need manual configuration."
fi

# Generate cloudflared configuration
log "Generating cloudflared configuration..."
cat > /etc/cloudflared/config.yml <<EOF
# Cloudflared configuration for $ENVIRONMENT environment
tunnel: $TUNNEL_NAME
credentials-file: /etc/cloudflared/credentials.json

# Metrics configuration
metrics: 0.0.0.0:2000
metrics-update-freq: ${METRICS_INTERVAL}s

# Logging configuration
loglevel: info
logfile: /var/log/cloudflared/cloudflared.log

# Transport protocol
protocol: quic

# Grace period for shutdown
grace-period: 30s

# Retry configuration
retries: 5
retry-duration: 30s

# Health check
no-autoupdate: true

# Ingress rules (will be configured separately via Cloudflare API)
ingress:
  - service: http_status:404
EOF

# Write credentials if token is available
if [ -n "$TUNNEL_TOKEN" ]; then
    echo "$TUNNEL_TOKEN" > /etc/cloudflared/credentials.json
    chown cloudflared:cloudflared /etc/cloudflared/credentials.json
    chmod 600 /etc/cloudflared/credentials.json
fi

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/cloudflared.service <<'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=cloudflared
Group=cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cloudflared
KillMode=mixed
KillSignal=SIGTERM

# Security hardening
PrivateTmp=yes
NoNewPrivileges=yes
ReadOnlyPaths=/
ReadWritePaths=/var/log/cloudflared
ReadWritePaths=/etc/cloudflared

# Resource limits
LimitNOFILE=65536
LimitNPROC=256

# Environment
Environment="TUNNEL_METRICS_INTERVAL=${METRICS_INTERVAL}"
Environment="TUNNEL_GRACE_PERIOD=30s"

[Install]
WantedBy=multi-user.target
EOF

# Configure CloudWatch agent
log "Configuring CloudWatch agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloudflared/cloudflared.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/cloudflared",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/cloudflared-setup.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/setup",
            "timezone": "UTC"
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
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
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
      "net": {
        "measurement": [
          {
            "name": "bytes_sent",
            "rename": "NET_SENT",
            "unit": "Bytes"
          },
          {
            "name": "bytes_recv",
            "rename": "NET_RECV",
            "unit": "Bytes"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
log "Starting CloudWatch agent..."
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

# Custom metrics collection script
log "Setting up custom metrics collection..."
cat > /usr/local/bin/cloudflared-metrics.sh <<'SCRIPT'
#!/bin/bash
# Collect and send cloudflared metrics to CloudWatch

NAMESPACE="CloudflareTunnel"
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
ENVIRONMENT="${environment}"

while true; do
    # Check if cloudflared is running
    if systemctl is-active --quiet cloudflared; then
        STATUS=1
    else
        STATUS=0
    fi
    
    # Send metric to CloudWatch
    aws cloudwatch put-metric-data \
        --namespace "$NAMESPACE" \
        --metric-name TunnelStatus \
        --value $STATUS \
        --dimensions Instance=$INSTANCE_ID,Environment=$ENVIRONMENT \
        --region "${region}"
    
    # Get tunnel metrics from cloudflared metrics endpoint
    if [ $STATUS -eq 1 ] && curl -s http://localhost:2000/metrics > /dev/null 2>&1; then
        METRICS=$(curl -s http://localhost:2000/metrics)
        
        # Extract and send connection count
        CONNECTIONS=$(echo "$METRICS" | grep -E "^cloudflared_tunnel_concurrent_requests_per_tunnel" | awk '{print $2}' | head -1)
        if [ -n "$CONNECTIONS" ]; then
            aws cloudwatch put-metric-data \
                --namespace "$NAMESPACE" \
                --metric-name ActiveConnections \
                --value "$CONNECTIONS" \
                --dimensions Instance=$INSTANCE_ID,Environment=$ENVIRONMENT \
                --region "${region}"
        fi
        
        # Extract and send tunnel status
        TUNNEL_UP=$(echo "$METRICS" | grep -E "^cloudflared_tunnel_tunnel_register_success" | awk '{print $2}' | head -1)
        if [ -n "$TUNNEL_UP" ]; then
            aws cloudwatch put-metric-data \
                --namespace "$NAMESPACE" \
                --metric-name TunnelRegistered \
                --value "$TUNNEL_UP" \
                --dimensions Instance=$INSTANCE_ID,Environment=$ENVIRONMENT \
                --region "${region}"
        fi
    fi
    
    sleep "${metrics_interval}"
done
SCRIPT

chmod +x /usr/local/bin/cloudflared-metrics.sh

# Create metrics service
cat > /etc/systemd/system/cloudflared-metrics.service <<EOF
[Unit]
Description=Cloudflared Metrics Collection
After=cloudflared.service
Requires=cloudflared.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared-metrics.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Health check script
log "Creating health check script..."
cat > /usr/local/bin/cloudflared-health.sh <<'SCRIPT'
#!/bin/bash
# Health check for cloudflared

# Check if service is running
if ! systemctl is-active --quiet cloudflared; then
    echo "ERROR: cloudflared service is not running"
    systemctl restart cloudflared
    exit 1
fi

# Check if tunnel is connected (via metrics endpoint)
if ! curl -sf http://localhost:2000/ready > /dev/null; then
    echo "ERROR: cloudflared tunnel is not ready"
    systemctl restart cloudflared
    exit 1
fi

echo "OK: cloudflared is healthy"
exit 0
SCRIPT

chmod +x /usr/local/bin/cloudflared-health.sh

# Setup cron for health checks
log "Setting up health check cron..."
echo "*/5 * * * * /usr/local/bin/cloudflared-health.sh >> /var/log/cloudflared/health.log 2>&1" | crontab -

# Configure log rotation
log "Configuring log rotation..."
cat > /etc/logrotate.d/cloudflared <<EOF
/var/log/cloudflared/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 cloudflared cloudflared
    postrotate
        systemctl reload cloudflared 2>/dev/null || true
    endscript
}
EOF

# Enable and start services
log "Starting cloudflared service..."
systemctl daemon-reload
systemctl enable cloudflared
systemctl enable cloudflared-metrics

if [ -n "$TUNNEL_TOKEN" ]; then
    systemctl start cloudflared
    systemctl start cloudflared-metrics
    
    # Wait for tunnel to come up
    log "Waiting for tunnel to connect..."
    for i in {1..30}; do
        if curl -sf http://localhost:2000/ready > /dev/null; then
            log "Tunnel connected successfully!"
            break
        fi
        sleep 10
    done
else
    log "Tunnel token not available. Service will need manual start after configuration."
fi

# Write instance metadata
log "Writing instance metadata..."
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
INSTANCE_TYPE=$(ec2-metadata --instance-type | cut -d " " -f 2)

cat > /etc/cloudflared/instance-info.json <<EOF
{
  "instance_id": "$INSTANCE_ID",
  "availability_zone": "$AVAILABILITY_ZONE",
  "instance_type": "$INSTANCE_TYPE",
  "environment": "$ENVIRONMENT",
  "tunnel_name": "$TUNNEL_NAME",
  "region": "$REGION",
  "setup_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Send completion notification to SSM Parameter
if [ -n "$TUNNEL_TOKEN" ]; then
    aws ssm put-parameter \
        --name "/$ENVIRONMENT/cloudflare/tunnel/$TUNNEL_NAME/instance" \
        --value "$INSTANCE_ID" \
        --type "String" \
        --overwrite \
        --region "$REGION" || true
fi

log "Cloudflared setup completed successfully!"
