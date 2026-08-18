#!/bin/sh
set -eu

if [ -f /etc/app/runtime.env ]; then
  set -a
  # shellcheck disable=SC1091
  . /etc/app/runtime.env
  set +a
fi

# Wait briefly for user-data to write the secret ARN (EC2 path).
i=0
while [ ! -f /etc/app/runtime.env.ready ] && [ "$i" -lt 20 ] && [ -z "${DB_SECRET_ARN:-}" ]; do
  i=$((i + 1))
  sleep 1
  if [ -f /etc/app/runtime.env ]; then
    set -a
    # shellcheck disable=SC1091
    . /etc/app/runtime.env
    set +a
  fi
done

# nginx uses /readyz: mark upstream down when the app is not ready.
(
  while true; do
    if wget -q -O /dev/null "http://127.0.0.1:${PORT:-3000}/readyz"; then
      rm -f /tmp/app-not-ready
    else
      touch /tmp/app-not-ready
    fi
    sleep 2
  done
) &

node /app/src/server.js &
exec nginx -g 'daemon off;'
