#!/usr/bin/env bash
# C8: grader command. Non-zero if any check fails.
set -euo pipefail
ROOT="${ROOT:-terraform/environments/${SERVICE:-service-a}}"
fail=0
# shellcheck source=/dev/null
source "$(cd "$(dirname "$0")" && pwd)/ls-mode.sh"
# shellcheck source=/dev/null
source "$(cd "$(dirname "$0")" && pwd)/aiven-tf-env.sh"

echo "== terraform plan empty after apply =="
if ! tflocal -chdir="$ROOT" plan -detailed-exitcode -var="app_ami_id=$(cat .ami-id)" >/tmp/verify-plan.txt; then
  code=$?
  if [ "$code" -eq 2 ]; then
    echo "FAIL: plan is not empty"
    cat /tmp/verify-plan.txt
    fail=1
  else
    echo "FAIL: terraform plan errored ($code)"
    fail=1
  fi
else
  echo "OK: plan empty"
fi

URL="$(scripts/instance-url.sh)"
echo "== GET /healthz @ $URL =="
code="$(curl -sS -o /tmp/healthz.json -w '%{http_code}' "$URL/healthz" || true)"
if [ "$code" != "200" ]; then echo "FAIL: /healthz HTTP $code"; fail=1; else echo "OK: /healthz 200"; fi

echo "== GET /readyz =="
code="$(curl -sS -o /tmp/readyz.json -w '%{http_code}' "$URL/readyz" || true)"
if [ "$code" != "200" ]; then echo "FAIL: /readyz HTTP $code"; cat /tmp/readyz.json; fail=1; else echo "OK: /readyz 200"; cat /tmp/readyz.json; fi

echo "== secret source =="
src="$(curl -sS "$URL/debug/secret-source")"
echo "$src"
python3 - "$src" <<'PY' || fail=1
import json,sys
d=json.loads(sys.argv[1])
assert d.get("arn") and d["arn"] != "unset" and d["arn"] != "TODO", d
assert d.get("versionId"), d
print("OK: secret resolved from", d["arn"])
PY

echo "== gitleaks =="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --no-git -r /tmp/gitleaks-image.json --exit-code 1 || { echo "FAIL: gitleaks"; fail=1; }
  gitleaks detect --source . --report-path /tmp/gitleaks-repo.json --exit-code 1 || { echo "FAIL: gitleaks history"; fail=1; }
  echo "OK: gitleaks zero findings"
else
  echo "WARN: gitleaks not installed on PATH (CI still gates it)"
fi

if [ "$fail" -ne 0 ]; then
  echo "make verify FAILED"
  exit 1
fi
echo "make verify PASSED"
