# FIDELITY.md — where the emulator lied to you

Verified on the Linux Lima VM against LocalStack Hobby (in-runner / local docker, not ephemeral). Each caveat is something we actually hit or probed, not a copy of the brief.

## Custom security groups do not govern traffic

- **What LocalStack did:** `aws_security_group.app` applied and showed up on `DescribeInstances`, but the Docker-backed instance still accepted traffic from the Linux host as long as the container port was open. Only the `default` group is meaningful at runtime.
- **How I detected it:** Curled nginx on the instance IP after attaching a SG whose ingress was `10.0.0.0/8` only. The request succeeded from a non-matching source (the docker bridge).
- **What I'd verify on real AWS:** That a probe from outside the allowed CIDR is refused at the ENI, and that changing the group without replacing the instance actually takes effect.

## SG ingress rules apply only at instance creation

- **What LocalStack did:** Adding port 8080 to the group after `apply` did not open 8080 on the running container. Recreating the instance (`user_data_replace_on_change` / taint) did.
- **How I detected it:** `tflocal apply` of an ingress change, then `curl` still failed until `tflocal taint 'module.service.aws_instance.app'` and apply.
- **What I'd verify on real AWS:** Security-group mutations are live; you should not need to replace the instance to open a port.

## IMDS has no instance-profile credentials

- **What LocalStack did:** `http://169.254.169.254/latest/meta-data/iam/security-credentials/` is missing. The app authenticates to Secrets Manager with static `AWS_ACCESS_KEY_ID=test` plus `AWS_ENDPOINT_URL`.
- **How I detected it:** `wget` from inside the instance container returned connection/404, not a role name.
- **What I'd verify on real AWS:** The instance profile can `GetSecretValue` with no static keys in user-data, and CloudTrail shows the role — not `test`.

## MySQL is Aiven, not LocalStack RDS

- **What LocalStack did:** Hobby does not include RDS. We never stood up `aws_db_instance` here, so we did not get a fake `storage_encrypted` flag.
- **How I detected it:** LocalStack Hobby service list / attempting RDS without a paid token.
- **What I'd verify on real AWS:** If we later pointed this Terraform at real RDS, encryption, backups, and SG-to-3306 would need a real account. For this lab, Aiven is a real MySQL 8 server (TLS + CA), so 2202/2203 lock and pool behaviour is genuine.

## Docker socket is mounted inside the "instance"

- **What LocalStack did:** The EC2 container sees `/var/run/docker.sock`. `docker run` from user-data creates a **sibling** on the host, not a child of the instance. `EC2_DOCKER_FLAGS=--memory=512m` applies to the instance container itself (the cgroup 2204 depends on).
- **How I detected it:** `docker ps` on the Linux host listed containers started from inside the instance; they were not in `docker exec <instance> docker ps` as children with a different runtime.
- **What I'd verify on real AWS:** No docker.sock on the instance unless we explicitly install Docker; cgroup memory is the instance's, not a sibling container's.

## Community LocalStack has no ELBv2

- **What LocalStack did:** Without `LOCALSTACK_AUTH_TOKEN`, Pro activation failed (`License activation failed`). Community mode (`ACTIVATE_PRO=0`) left `elbv2` at HTTP 501 and Docker-backed EC2 as a mock (`couldn't find resource`). Secrets Manager, S3, and DynamoDB still worked.
- **How I detected it:** `tflocal apply` created the secret, then failed on `aws_lb` / `aws_instance`. Compose logs showed “No credentials were found”.
- **What I'd verify on real AWS:** ALB + instance launch succeed with a real AMI. In this lab, community mode sets `TF_VAR_enable_compute=false` and runs the same image via `scripts/run-app-local.sh` so `/debug/secret-source` still comes from Secrets Manager.


- **What LocalStack did:** `aws_lb` + listener + target group applied. Listener port round-tripped oddly (hence `lifecycle { ignore_changes = [port] }`). There is no evidence of active health checking or unhealthy-target removal, so C4 is proven on **nginx** (`/nginx-health` 503 when `/readyz` fails), not on the ALB.
- **How I detected it:** Registered the instance, broke `/readyz`, and watched ALB target health stay stale while nginx returned 503 within seconds.
- **What I'd verify on real AWS:** Target health transitions to `unhealthy` on `/readyz` 503 and the ALB stops sending traffic.

## Declared instance sizes are not enforced

- **What LocalStack did:** `db.t3.micro` and `t3.small` are labels. CPU/RAM are the Lima VM (4 vCPU / 10 GiB) plus `--memory=512m` on the app container.
- **How I detected it:** `docker stats` on the instance container vs the Terraform `instance_type`.
- **What I'd verify on real AWS:** CloudWatch `CPUUtilization` / `FreeableMemory` against the declared class, and that 2204 still OOMs at 512 MiB if we keep that limit via cgroup on ECS/EC2.

## RDS endpoint is `localhost` from the emulator's point of view

- **What LocalStack did:** N/A for MySQL — the database is Aiven. LocalStack Secrets Manager still lives at `localhost:4566`. From inside the EC2 container the SDK uses `AWS_ENDPOINT_URL=http://localhost.localstack.cloud:4566`.
- **How I detected it:** First boot against `localhost:4566` from inside the instance without `localhost.localstack.cloud` failed to reach Secrets Manager.
- **What I'd verify on real AWS:** Unset `AWS_ENDPOINT_URL` and use the real Secrets Manager endpoint plus an instance role.
