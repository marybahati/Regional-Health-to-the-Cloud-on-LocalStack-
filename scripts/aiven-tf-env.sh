#!/usr/bin/env bash
# Map AIVEN_* from .env into TF_VAR_* so Terraform never sees a committed tfvars file.
set -euo pipefail
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Aiven UI / some .env files use DATABASE; docs and CI use DB.
export AIVEN_MYSQL_DB="${AIVEN_MYSQL_DB:-${AIVEN_MYSQL_DATABASE:-defaultdb}}"

if [ -z "${TF_VAR_db_host:-}" ] && [ -n "${AIVEN_MYSQL_HOST:-}" ]; then
  export TF_VAR_db_host="$AIVEN_MYSQL_HOST"
  export TF_VAR_db_port="${AIVEN_MYSQL_PORT:?set AIVEN_MYSQL_PORT}"
  export TF_VAR_db_username="${AIVEN_MYSQL_USER:?set AIVEN_MYSQL_USER}"
  export TF_VAR_db_password="${AIVEN_MYSQL_PASSWORD:?set AIVEN_MYSQL_PASSWORD}"
  export TF_VAR_db_name="${AIVEN_MYSQL_DB}"
fi
if [ -z "${TF_VAR_db_ca_cert:-}" ]; then
  if [ -n "${AIVEN_MYSQL_CA:-}" ]; then
    export TF_VAR_db_ca_cert="$AIVEN_MYSQL_CA"
  elif [ -n "${AIVEN_CA_PATH:-}" ] && [ -f "${AIVEN_CA_PATH}" ]; then
    export TF_VAR_db_ca_cert="$(cat "$AIVEN_CA_PATH")"
  elif [ -f ca.pem ]; then
    export TF_VAR_db_ca_cert="$(cat ca.pem)"
  fi
fi

missing=()
[ -n "${TF_VAR_db_host:-}" ] || missing+=(TF_VAR_db_host/AIVEN_MYSQL_HOST)
[ -n "${TF_VAR_db_port:-}" ] || missing+=(TF_VAR_db_port/AIVEN_MYSQL_PORT)
[ -n "${TF_VAR_db_username:-}" ] || missing+=(TF_VAR_db_username/AIVEN_MYSQL_USER)
[ -n "${TF_VAR_db_password:-}" ] || missing+=(TF_VAR_db_password/AIVEN_MYSQL_PASSWORD)
[ -n "${TF_VAR_db_ca_cert:-}" ] || missing+=(TF_VAR_db_ca_cert/"ca.pem or AIVEN_MYSQL_CA")
if [ "${#missing[@]}" -ne 0 ]; then
  echo "Aiven MySQL vars missing. Follow docs/aiven-mysql.md" >&2
  echo "Missing: ${missing[*]}" >&2
  echo "Need a gitignored .env plus ca.pem (Download CA on the Aiven service Overview page)." >&2
  exit 1
fi
