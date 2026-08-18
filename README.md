# Regional Health — Service A rehost (LocalStack + Aiven)

**New here? Start at [docs/README.md](docs/README.md).** That folder is the beginner path: Linux vs VM, LocalStack, Aiven MySQL, GitHub secrets, first `make up`.

This checkout is **Service A only**. Teammates rehost B and C on the same group modules.

## What changed from the original brief

LocalStack Hobby does **not** include RDS or ECR. We do not pay for those.

| Original brief | This repo |
|---|---|
| RDS MySQL on LocalStack | [Aiven for MySQL](https://aiven.io/) (free, real MySQL + TLS) |
| ECR | No registry. Image is built, scanned, tagged `localstack-ec2/app:ami-<sha12>` |

Terraform still writes the DB envelope to **Secrets Manager**. The app still calls `GetSecretValue` at boot. User-data still gets the **ARN only**.

## Machine: Linux is required

LocalStack EC2 is unreachable from macOS Docker Desktop. Use native Linux, the Lima VM, or Codespaces. Details: [docs/setup-linux.md](docs/setup-linux.md) vs [docs/setup-vm.md](docs/setup-vm.md).

## Right-sizing

| Resource | Value | Why |
|---|---|---|
| Aiven MySQL | Free plan (1 GB, 76 connections) | 10,000 patients is a few MB |
| EC2 instance type | `t3.small` (declared IaC; LocalStack does not enforce size) | Headroom for nginx + Node |
| App cgroup | `--memory=512m` (`EC2_DOCKER_FLAGS`) | Makes 2204 OOM reproducible |

## One command (on Linux, after Aiven + token)

See [docs/first-run.md](docs/first-run.md).

```bash
set -a && source .env && set +a
make up
make verify
```

## OIDC (E2)

Commented `configure-aws-credentials` is in `.github/workflows/golden.yml`. Trust policy: `iam/github-oidc-trust.json`.

**What breaks if `sub` is `repo:<org>/*`?** Any repo in the org can assume the deploy role. Scoping to `repo:<org>/<repo>:ref:refs/heads/main` limits that to this repo’s `main` branch.

## Layout

- `docs/` — start here if you have never done this
- `terraform/modules/data` — Secrets Manager envelope (Aiven details in, password never in git)
- `terraform/modules/service` — EC2 + nginx user-data + ALB IaC
- `terraform/environments/service-a` — Service A root
- `api/` — Service A
