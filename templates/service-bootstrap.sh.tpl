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

apt-get install -y postgresql-client redis-tools

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
aws ecr get-login-password --region ${region} |
	docker login --username AWS --password-stdin ${ecr_registry}

docker pull ${image}

# Run container with environment from Systems Manager Parameter Store
DB_URL=$(aws ssm get-parameter --region ${region} --name ${db_url_param} --query 'Parameter.Value' --output text)
DB_PASS=$(aws ssm get-parameter --region ${region} --name ${db_app_password_param} --with-decryption --query 'Parameter.Value' --output text)
REDIS_HOST=$(aws ssm get-parameter --region ${region} --name ${redis_endpoint_param} --query 'Parameter.Value' --output text)
REDIS_PORT=$(aws ssm get-parameter --region ${region} --name ${redis_port_param} --query 'Parameter.Value' --output text)
REDIS_AUTH=$(aws ssm get-parameter --region ${region} --name ${redis_auth_param} --with-decryption --query 'Parameter.Value' --output text)

# Ensure the app's least-privilege DB login exists — created here (not by Terraform) because
# this instance is the only thing allowed through rds-sg; idempotent, safe on every boot/refresh.
ADMIN_DB_PASS=$(aws ssm get-parameter --region ${region} --name ${db_admin_password_param} --with-decryption --query 'Parameter.Value' --output text)

PGPASSWORD="$ADMIN_DB_PASS" psql -h ${db_host} -p ${db_port} -U ${db_admin_username} -d ${db_name} \
	-v ON_ERROR_STOP=1 -v app_pass="$DB_PASS" <<'SQL'
SELECT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${db_app_username}') AS role_exists \gset

\if :role_exists
ALTER ROLE ${db_app_username} WITH PASSWORD :'app_pass';
\else
CREATE ROLE ${db_app_username} LOGIN PASSWORD :'app_pass';
\endif

GRANT CREATE, USAGE ON SCHEMA public TO ${db_app_username};
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO ${db_app_username};
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO ${db_app_username};
ALTER DEFAULT PRIVILEGES FOR ROLE ${db_admin_username} IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO ${db_app_username};
ALTER DEFAULT PRIVILEGES FOR ROLE ${db_admin_username} IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO ${db_app_username};
SQL

docker run -d \
	--name ${container_name} \
	-p ${container_port}:${container_port} \
	-e SERVER_PORT="${container_port}" \
	-e SPRING_DATASOURCE_URL="$DB_URL" \
	-e SPRING_DATASOURCE_USERNAME="${db_app_username}" \
	-e SPRING_DATASOURCE_PASSWORD="$DB_PASS" \
	-e SPRING_DATA_REDIS_HOST="$REDIS_HOST" \
	-e SPRING_DATA_REDIS_PORT="$REDIS_PORT" \
	-e SPRING_DATA_REDIS_SSL_ENABLED="true" \
	-e SPRING_DATA_REDIS_DATABASE="${redis_database_index}" \
	-e SPRING_DATA_REDIS_PASSWORD="$REDIS_AUTH" \
	-e AWS_REGION="${region}" \
	-e CLOUDWATCH_METRICS_ENABLED="true" \
	-e MANAGEMENT_METRICS_TAGS_ENVIRONMENT="${environment}" \
	-e CLOUDWATCH_METRICS_NAMESPACE="${metrics_namespace}" \
	--restart always \
	${image}
