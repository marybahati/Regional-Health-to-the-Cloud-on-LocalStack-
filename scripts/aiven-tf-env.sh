#!/usr/bin/env bash
set -euo pipefail
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
if [ -z "${TF_VAR_db_host:-}" ] || [ -z "${TF_VAR_db_password:-}" ] || [ -z "${TF_VAR_db_ca_cert:-}" ]; then
  echo "Aiven MySQL vars missing. Follow docs/aiven-mysql.md" >&2
  echo "Need TF_VAR_db_host, TF_VAR_db_port, TF_VAR_db_username, TF_VAR_db_password, TF_VAR_db_ca_cert" >&2
  exit 1
fi
