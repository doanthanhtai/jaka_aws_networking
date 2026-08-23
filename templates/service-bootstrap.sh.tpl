#!/bin/bash
set -euo pipefail

# Update system
apt-get update
apt-get install -y docker.io curl unzip

# Start Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# AWS CLI v2 (not preinstalled on the Ubuntu 22.04 base image)
if ! command -v aws >/dev/null 2>&1; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

# CloudWatch Agent
curl -s -o /tmp/amazon-cloudwatch-agent.deb \
  "https://s3.${region}.amazonaws.com/amazoncloudwatch-agent-${region}/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c ssm:${cw_ssm_parameter_name} \
  -s

# Pull pre-built image from ECR
aws ecr get-login-password --region ${region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

docker pull ${image}

# Run container with environment from Systems Manager Parameter Store
DB_URL=$(aws ssm get-parameter --region ${region} --name ${db_url_param} --query 'Parameter.Value' --output text)
DB_PASS=$(aws ssm get-parameter --region ${region} --name ${db_password_param} --with-decryption --query 'Parameter.Value' --output text)

docker run -d \
  --name ${container_name} \
  -p ${container_port}:${container_port} \
  -e SPRING_DATASOURCE_URL="$DB_URL" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASS" \
  --restart always \
  ${image}
