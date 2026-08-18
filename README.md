# Regional Health to the Cloud on LocalStack — group-5

Group platform repo for Assignment 2. **Service B (Warga)** is the first individual rehost wired here; Mary and Sharon add `terraform/environments/service-a` and `service-c` on the same modules.

**Due:** Wednesday 19 August 2026, 09:00 EAT

## Slack updates (authoritative)

- **Database:** Aiven MySQL free tier — not LocalStack RDS
- **Registry:** no ECR — image is built, scanned, and tagged `localstack-ec2/service-b:ami-<sha12>`
- LocalStack runs **inside** the GitHub runner (in-runner). Do not use hosted/ephemeral instances.

## What lives here

| Path | Owner |
|---|---|
| `terraform/modules/data` | Group — Aiven creds → Secrets Manager |
| `terraform/modules/service` | Group — EC2 + nginx + ALB IaC |
| `terraform/environments/service-b` | Warga — individual root |
| `api/` | Service B app: secrets, `/healthz`, `/readyz` |
| `.github/workflows/rehost-golden.yml` | Golden pipeline |
| `evidence/` | Graded artifacts |

## Prerequisites (personal — do not share)

```bash
export LOCALSTACK_AUTH_TOKEN="..."
export AIVEN_MYSQL_HOST="..."
export AIVEN_MYSQL_PORT="..."
export AIVEN_MYSQL_USER="avnadmin"
export AIVEN_MYSQL_PASSWORD="..."
```

Add the same names as GitHub Actions secrets.

## Right-sizing

| Resource | Value | Why |
|---|---|---|
| EC2 | `t3.small` | nginx + Node app headroom; `t3.micro` is too tight |
| DB | Aiven free MySQL 8.0 | real managed MySQL with TLS; RDS is not on Hobby |
| App memory | `--memory=512m` | makes incident 2204 OOM reproducible |
| Multi-AZ | n/a (Aiven free) | single instance; availability trade-off accepted for the lab |

## Commands

```bash
# One-time: S3 state + DynamoDB lock on LocalStack
make bootstrap

# Seed Aiven (once)
mysql -h "$AIVEN_MYSQL_HOST" -P "$AIVEN_MYSQL_PORT" -u avnadmin -p \
  --ssl-mode=REQUIRED < sql/schema.sql

# Stand up Service B from zero
make up

# Grader check (must fail if any gate fails)
make verify
```

`make up` tags the image as `localstack-ec2/service-b:ami-<first-12-of-git-sha>` then runs `tflocal apply`.

## Secrets (C3)

User-data receives **ARN + LocalStack endpoint only**. The app calls `GetSecretValue` at boot using `AWS_ENDPOINT_URL`. There is no `if (isLocalStack)` branch.

## E2 — OIDC design

The deploy job in `.github/workflows/rehost-golden.yml` has a commented `configure-aws-credentials` block. Trust policy: `docs/oidc-trust-policy.json`.

**What breaks if `sub` is `repo:<org>/*`?** Any repository in that org — including a fork or a throwaway repo a compromised workflow can push to — can assume the deploy role. Scoping to `repo:<org>/<repo>:ref:refs/heads/main` limits assumption to this repo's main branch.

## Group vs individual

Each member: author ≥1 module PR, review ≥2 others. Record in `CONTRIBUTIONS.md`. Individual marks require **your** Aiven DB, LocalStack token, and Service B deploy — not a teammate's.
