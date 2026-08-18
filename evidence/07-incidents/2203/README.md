# 2203 — ER_LOCK_WAIT_TIMEOUT / lock-wait time

`FAULT_2203=1` holds `SELECT ... FOR UPDATE` on `patients.id=1`. Concurrent `POST /tx/lock` wait, then hit `innodb_lock_wait_timeout`.

```bash
k6 run -e BASE_URL="$URL" load-tests/2203.js
```

RDS MySQL is a real server: lock waits are genuine InnoDB, unlike a mocked RDS. Alert OPS-2203 uses `mysql_lock_wait_seconds`.
