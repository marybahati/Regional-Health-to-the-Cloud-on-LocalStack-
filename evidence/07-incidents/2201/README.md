# 2201 — per-route p95 + rows-examined

Healthy app uses `national_id = ?` (index). Fault injection: `FAULT_2201=1` switches `/patients` to `LIKE %q%` on `notes`, which examines the full 10k rows.

```bash
# inject
# (recreate instance or docker exec env — for the lab, rebuild AMI with FAULT_2201=1
# or POST a note that the demo uses FAULT_2201 on a throwaway apply)
k6 run -e BASE_URL="$URL" load-tests/2201.js
# alert OPS-2201 should fire; dashboard panel "2201 — per-route p95"
# clear: unset FAULT_2201, recreate instance, alert goes back to inactive
```

Mechanism: missing predicate selectivity. Payload and handler rows scale with table size, not with the one row the caller wanted.
