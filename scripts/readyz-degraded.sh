#!/usr/bin/env bash
# C4 evidence: rotate the secret to a wrong password, show /readyz 503 + nginx 503, then restore.
set -euo pipefail
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ROOT="${ROOT:-terraform/environments/service-a}"
OUT="${1:-evidence/04-health/readyz-degraded.txt}"
mkdir -p "$(dirname "$OUT")"
URL="$(scripts/instance-url.sh)"
SECRET_ARN="$(tflocal -chdir="$ROOT" output -raw secret_arn)"
GOOD="$(aws --endpoint-url "$ENDPOINT" secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)"

app_container() {
  if [ -n "${APP_CONTAINER_NAME:-}" ]; then
    echo "$APP_CONTAINER_NAME"
    return
  fi
  n="$(docker ps --format '{{.Names}}' | awk '/localstack-ec2/ {print; exit}')"
  if [ -z "$n" ]; then
    n="$(docker ps --format '{{.Names}}' | awk '/service-a-e2e/ {print; exit}')"
  fi
  echo "$n"
}

reload_secret() {
  curl -sS -X POST "$URL/debug/reload-secret" || true
  echo
  cid="$(app_container | head -n1)"
  if [ -n "$cid" ]; then
    docker exec "$cid" wget -q -O- --post-data='' http://127.0.0.1:3000/debug/reload-secret 2>/dev/null || true
    echo
  fi
}

{
  echo "=== baseline ==="
  echo "GET $URL/readyz"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/readyz" || true
  echo "GET $URL/nginx-health"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/nginx-health" || true

  echo
  echo "=== break secret (rotate to wrong password) ==="
  python3 - "$GOOD" <<'PY' > /tmp/bad-secret.json
import json,sys
d=json.loads(sys.argv[1])
d["password"]="intentionally-wrong-password"
print(json.dumps(d))
PY
  aws --endpoint-url "$ENDPOINT" secretsmanager put-secret-value \
    --secret-id "$SECRET_ARN" --secret-string "$(cat /tmp/bad-secret.json)" >/dev/null
  reload_secret
  sleep 3
  echo "GET $URL/readyz (expect 503)"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/readyz" || true
  sleep 3
  echo "GET $URL/nginx-health (expect 503 — nginx pulled upstream)"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/nginx-health" || true

  echo
  echo "=== restore secret ==="
  aws --endpoint-url "$ENDPOINT" secretsmanager put-secret-value \
    --secret-id "$SECRET_ARN" --secret-string "$GOOD" >/dev/null
  reload_secret
  sleep 4
  echo "GET $URL/readyz (expect 200)"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/readyz" || true
  sleep 3
  echo "GET $URL/nginx-health (expect 200)"
  curl -sS -w "\nHTTP %{http_code}\n" "$URL/nginx-health" || true
} | tee "$OUT"
