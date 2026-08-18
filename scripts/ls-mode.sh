#!/usr/bin/env bash
# Community vs Pro LocalStack. Source this after .env.
set -euo pipefail
export S3_HOSTNAME="${S3_HOSTNAME:-localhost}"
if [ -n "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
  export ACTIVATE_PRO="${ACTIVATE_PRO:-1}"
  # 2026 Hobby/freemium activates the image but does not include Docker-backed EC2 or ELBv2.
  # Paid licenses can set TF_VAR_enable_compute=true.
  export TF_VAR_enable_compute="${TF_VAR_enable_compute:-false}"
else
  export ACTIVATE_PRO="${ACTIVATE_PRO:-0}"
  export TF_VAR_enable_compute="${TF_VAR_enable_compute:-false}"
  echo "LOCALSTACK_AUTH_TOKEN unset — community mode (Secrets Manager + local app container; no Docker-backed EC2 / ELBv2)" >&2
fi
