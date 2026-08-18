#!/usr/bin/env bash
# Seed Aiven MySQL with $PATIENT_COUNT patients. Password comes from Secrets Manager.
set -euo pipefail
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ROOT="${ROOT:-terraform/environments/service-a}"
COUNT="${PATIENT_COUNT:-$(tflocal -chdir="$ROOT" output -raw patient_count)}"
HOST="$(tflocal -chdir="$ROOT" output -raw db_endpoint)"
PORT="$(tflocal -chdir="$ROOT" output -raw db_port)"
DB="$(tflocal -chdir="$ROOT" output -raw db_name)"
USER="$(tflocal -chdir="$ROOT" output -raw db_username)"
SECRET_ARN="$(tflocal -chdir="$ROOT" output -raw secret_arn)"
SECRET_JSON="$(aws --endpoint-url "$ENDPOINT" secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" --query SecretString --output text)"
PASS="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["password"])' "$SECRET_JSON")"
CA_FILE="$(mktemp)"
python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("ca",""))' "$SECRET_JSON" > "$CA_FILE"
trap 'rm -f "$CA_FILE"' EXIT

echo "seeding $COUNT patients into $USER@$HOST:$PORT/$DB (Aiven, TLS)"

mysql_cmd() {
  local extra=(--protocol=TCP -h "$HOST" -P "$PORT" -u "$USER" "-p$PASS" --ssl-mode=REQUIRED)
  if [ -s "$CA_FILE" ]; then
    extra+=(--ssl-ca="$CA_FILE")
  fi
  extra+=("$DB")
  if command -v mysql >/dev/null 2>&1; then
    mysql "${extra[@]}" "$@"
  else
    docker run --rm -i mysql:8.0 mysql "${extra[@]}" "$@"
  fi
}

mysql_cmd < sql/schema.sql

EXISTING="$(mysql_cmd -N -e "SELECT COUNT(*) FROM patients;" | tr -d '[:space:]')"
if [ "${EXISTING:-0}" -ge "$COUNT" ]; then
  echo "already have $EXISTING patients (>= $COUNT); skip insert"
else
  python3 - "$COUNT" <<'PY' | mysql_cmd
import sys
count = int(sys.argv[1])
print("INSERT INTO patients (national_id, full_name, date_of_birth, district, notes) VALUES")
districts = ["Kampala", "Gulu", "Mbale", "Mbarara", "Arua", "Jinja"]
rows = []
for i in range(1, count + 1):
    nid = f"UG{i:08d}"
    name = f"Patient {i}"
    dob = f"{1950 + (i % 60):04d}-{(i % 12) + 1:02d}-{(i % 28) + 1:02d}"
    district = districts[i % len(districts)]
    notes = f"seed row {i} district={district}"
    rows.append(f"('{nid}','{name}','{dob}','{district}','{notes}')")
    if len(rows) == 500 or i == count:
        print(",\n".join(rows) + ";")
        if i != count:
            print("INSERT INTO patients (national_id, full_name, date_of_birth, district, notes) VALUES")
        rows = []
PY
fi

echo "seed complete"
mysql_cmd -e "SELECT COUNT(*) AS patient_count FROM patients;"
