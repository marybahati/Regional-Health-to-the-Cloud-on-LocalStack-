# 2202 — pool saturation while the DB is idle

`FAULT_2202=1` makes `POST /pool/hold` keep a pooled connection for `hold_ms` without running a query. k6 VUs > pool size ⇒ `mysql_pool_queued > 0` while MySQL `Threads_running` stays low.

```bash
k6 run -e BASE_URL="$URL" load-tests/2202.js
```

Mechanism: the bottleneck is the **client pool**, not InnoDB. RDS is a real MySQL so `SHOW PROCESSLIST` stays idle — same bug as A1, now on a managed endpoint.
