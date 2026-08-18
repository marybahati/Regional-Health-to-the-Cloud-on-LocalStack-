#!/usr/bin/env bash
# Community / no-Pro path: run the same image LocalStack would use as an AMI,
# with DB_SECRET_ARN from Secrets Manager (never the password in the process list
# from Terraform — the SDK fetches it at boot).
set -euo pipefail
ROOT="${ROOT:-terraform/environments/service-a}"
NAME="${APP_CONTAINER_NAME:-service-a-e2e}"
IMAGE="${IMAGE:-service-a:local}"
PUBLISH="${APP_PUBLISH_PORT:-18080}"
NETWORK="${APP_DOCKER_NETWORK:-observability_default}"
LS_ENDPOINT="${APP_AWS_ENDPOINT_URL:-http://localstack:4566}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

SECRET_ARN="$(tflocal -chdir="$ROOT" output -raw secret_arn)"
test -n "$SECRET_ARN"

docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK"

MEM="${EC2_DOCKER_FLAGS:---memory=512m}"

docker rm -f "$NAME" >/dev/null 2>&1 || true
# host-gateway: GitHub's default bridge has no container DNS, so LocalStack
# must be reached via the published host port, not http://localstack-main:4566.
# shellcheck disable=SC2086
docker run -d --name "$NAME" ${MEM} \
  --network "$NETWORK" \
  --add-host=host.docker.internal:host-gateway \
  --add-host=localstack:host-gateway \
  -p "${PUBLISH}:8080" \
  -e SERVICE_NAME=service-a \
  -e DB_SECRET_ARN="$SECRET_ARN" \
  -e AWS_ENDPOINT_URL="$LS_ENDPOINT" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  "$IMAGE" >/dev/null

ok=0
for _ in $(seq 1 40); do
  if curl -sf "http://127.0.0.1:${PUBLISH}/readyz" >/dev/null; then
    ok=1
    break
  fi
  sleep 2
done
if [ "$ok" -ne 1 ]; then
  echo "app container did not become ready" >&2
  curl -sS "http://127.0.0.1:${PUBLISH}/readyz" >&2 || true
  echo >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi
echo "http://127.0.0.1:${PUBLISH}"
