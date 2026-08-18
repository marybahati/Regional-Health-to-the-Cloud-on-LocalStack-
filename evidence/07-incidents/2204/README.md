# 2204 — memory vs 512Mi limit + restart count (full walk-through)

This is the full incident: inject → alert fires → dashboard shows it → name the mechanism.

**Most deterministic injection (no load tuning):** stop the app process so `up{job="capacity-api"} == 0`.

```bash
# find the instance container
docker ps --format '{{.ID}} {{.Names}}' | grep localstack-ec2
docker exec <id> pkill -f 'node /app/src/server.js' || docker pause <id>
# Prometheus: OPS-2204 firing; Grafana panel "2204 — up / restarts"
# recover
docker unpause <id>  # or recreate instance
```

**Load-based injection:** `FAULT_2204=1` on `GET /export` materialises 10k rows × 80 copies into RSS. `EC2_DOCKER_FLAGS=--memory=512m` is the cgroup ceiling.

Mechanism: unbounded materialisation of a result set in the Node heap. The process is killed by the cgroup OOM killer; nginx `/readyz` watcher then returns 503 until the process is back. On A1 this was a local Compose memory limit; here it is the LocalStack EC2 container flag — same failure mode, cloud-shaped isolation.

Compared to A1 Compose: RDS did not change 2204 (it is not a DB bug). The managed tier *did* change where the cgroup lives (instance container, not a named Compose service).
