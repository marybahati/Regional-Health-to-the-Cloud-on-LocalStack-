#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx docker.io curl

cat >/etc/nginx/conf.d/${service_name}.conf <<'NGINX_EOF'
${nginx_conf}
NGINX_EOF

rm -f /etc/nginx/sites-enabled/default
systemctl enable nginx
systemctl restart nginx

# ARN + endpoint only. The app calls GetSecretValue at boot.
docker run -d --name ${service_name} --restart unless-stopped \
  --memory=512m \
  -p ${app_port}:${app_port} \
  -e PORT=${app_port} \
  -e BIND_HOST=0.0.0.0 \
  -e DB_SECRET_ARN=${secret_arn} \
  -e AWS_ENDPOINT_URL=${aws_endpoint_url} \
  -e AWS_REGION=${aws_region} \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  ${app_image}
