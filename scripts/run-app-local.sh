#!/usr/bin/env bash
# Community / no-Pro path: run the same image LocalStack would use as an AMI,
# with DB_SECRET_ARN from Secrets Manager (never the password in the process list
# from Terraform — the SDK fetches it at boot).
set -euo pipefail
SERVICE_NAME="${SERVICE_NAME:-${SERVICE:-service-a}}"
ROOT="${ROOT:-terraform/environments/${SERVICE_NAME}}"
NAME="${APP_CONTAINER_NAME:-${SERVICE_NAME}-e2e}"
IMAGE="${IMAGE:-${SERVICE_NAME}:local}"
NETWORK="${APP_DOCKER_NETWORK:-observability_default}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

SECRET_ARN="$(tflocal -chdir="$ROOT" output -raw secret_arn)"
test -n "$SECRET_ARN"

MEM="${EC2_DOCKER_FLAGS:---memory=512m}"

# C7 fault injection: forward these through if the caller set them, so an
# incident can be triggered without hand-editing this script each time.
EXTRA_ENV=()
for v in FAULT_2201 FAULT_2202 FAULT_2203 FAULT_2204 LOCK_HOLD_MS; do
  if [ -n "${!v:-}" ]; then
    EXTRA_ENV+=(-e "$v=${!v}")
  fi
done

docker rm -f "$NAME" >/dev/null 2>&1 || true

# Host network (CI): LocalStack's published port is 127.0.0.1:4566 on the runner.
# A container cannot reach that via host-gateway / host.docker.internal.
# Compose network (local): hostname "localstack" on observability_default.
if [ "$NETWORK" = "host" ]; then
  PUBLISH="${APP_PUBLISH_PORT:-8080}"
  LS_ENDPOINT="${APP_AWS_ENDPOINT_URL:-http://127.0.0.1:4566}"
  # shellcheck disable=SC2086
  docker run -d --name "$NAME" ${MEM} \
    --network host \
    -e SERVICE_NAME="$SERVICE_NAME" \
    -e DB_SECRET_ARN="$SECRET_ARN" \
    -e AWS_ENDPOINT_URL="$LS_ENDPOINT" \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    "${EXTRA_ENV[@]}" \
    "$IMAGE" >/dev/null
else
  PUBLISH="${APP_PUBLISH_PORT:-18080}"
  LS_ENDPOINT="${APP_AWS_ENDPOINT_URL:-http://localstack:4566}"
  docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK"
  # shellcheck disable=SC2086
  docker run -d --name "$NAME" ${MEM} \
    --network "$NETWORK" \
    -p "${PUBLISH}:8080" \
    -e SERVICE_NAME="$SERVICE_NAME" \
    -e DB_SECRET_ARN="$SECRET_ARN" \
    -e AWS_ENDPOINT_URL="$LS_ENDPOINT" \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    "${EXTRA_ENV[@]}" \
    "$IMAGE" >/dev/null
fi

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
  echo "== nginx /readyz (may be a generic 503) ==" >&2
  curl -sS -D - "http://127.0.0.1:${PUBLISH}/readyz" >&2 || true
  echo >&2
  echo "== node /readyz (bypass nginx) ==" >&2
  docker exec "$NAME" wget -qO- "http://127.0.0.1:3000/readyz" >&2 || true
  echo >&2
  echo "== /debug/secret-source ==" >&2
  curl -sS "http://127.0.0.1:${PUBLISH}/debug/secret-source" >&2 || true
  echo >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi
echo "http://127.0.0.1:${PUBLISH}"
