#!/usr/bin/env bash
# Resolve the Service A URL: Docker-backed EC2 (Pro) or published local container.
set -euo pipefail
SERVICE="${SERVICE:-service-a}"
ROOT="${ROOT:-terraform/environments/$SERVICE}"
PORT="${APP_HTTP_PORT:-8080}"

if [ -n "${SERVICE_URL:-}" ]; then
  echo "${SERVICE_URL%/}"
  exit 0
fi

IID=""
if tflocal -chdir="$ROOT" output -raw instance_id >/tmp/instance-id.txt 2>/dev/null; then
  IID="$(tr -d '[:space:]' </tmp/instance-id.txt)"
fi
if [ -n "$IID" ] && [ "$IID" != "null" ] && [ "$IID" != "None" ]; then
  CID="$(docker ps -q --filter "name=localstack-ec2.${IID}" --filter "name=${IID}" | head -n1)"
  if [ -z "$CID" ]; then
    CID="$(docker ps --format '{{.ID}} {{.Names}}' | awk '/localstack-ec2/ {print $1; exit}')"
  fi
  if [ -n "$CID" ]; then
    IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")"
    if [ -n "$IP" ]; then
      echo "http://${IP}:${PORT}"
      exit 0
    fi
  fi
fi

CID="$(docker ps -q --filter "name=$SERVICE-e2e" | head -n1)"
if [ -n "$CID" ]; then
  echo "http://127.0.0.1:${APP_PUBLISH_PORT:-18080}"
  exit 0
fi

echo "could not find $SERVICE (no EC2 instance, no $SERVICE-e2e container)" >&2
docker ps >&2
exit 1
