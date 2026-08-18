# LocalStack setup

LocalStack is a local emulator of AWS APIs. Your Terraform is **real AWS Terraform**; only the endpoints point at `http://localhost:4566`.

Official docs:

- Getting started: https://docs.localstack.cloud/aws/getting-started/
- Auth token: https://docs.localstack.cloud/aws/getting-started/auth-token/
- Docker install: https://docs.localstack.cloud/aws/getting-started/installation/
- EC2 (why Linux): https://docs.localstack.cloud/aws/services/ec2/
- Secrets Manager: https://docs.localstack.cloud/aws/services/secretsmanager/
- Terraform (`tflocal`): https://docs.localstack.cloud/aws/tooling/terraform/
- GitHub Actions (in-runner, not ephemeral): https://docs.localstack.cloud/aws/integrations/continuous-integration/github-actions/

## Free Hobby tier — what we use, what we do not

Sign up with a **personal** account. Hobby is licensed for individual, non-commercial use.

Included for this lab: **EC2** (Docker-backed), **Secrets Manager**, **S3**, **DynamoDB**.

**Not** on Hobby (do not use them here):

- RDS — we use [Aiven MySQL](aiven-mysql.md) instead
- ECR — the image is built and scanned in CI and tagged as `localstack-ec2/app:ami-<sha12>` locally. No registry.
- Cloud Pods / ephemeral “preview” instances — CI starts LocalStack **inside the GitHub runner**. Do not use hosted ephemeral URLs; the EC2 port is only reachable from the Linux host.

Hobby console: https://app.localstack.cloud/

## 1. Create an account and a Hobby token

1. Open https://app.localstack.cloud/ and sign up (GitHub login is fine).
2. Go to **Settings → Auth Tokens** (also described here: https://docs.localstack.cloud/aws/getting-started/auth-token/).
3. Create a **Hobby** auth token.
4. Copy it somewhere safe. Treat it like a password.

This is the **only** LocalStack secret in the assignment.

## 2. Put the token in your shell (Linux or the VM)

Never paste the token into a git-tracked file.

```bash
# in the Linux shell where you will run make up
export LOCALSTACK_AUTH_TOKEN='paste-the-token-here'
```

To keep it across sessions, add that line to `~/.bashrc` or use a **gitignored** `.env`:

```bash
cp .env.example .env
# edit .env and fill LOCALSTACK_AUTH_TOKEN
set -a
source .env
set +a
```

`.env` is already in `.gitignore`.

If the token is missing, this repo sets `ACTIVATE_PRO=0` and `TF_VAR_enable_compute=false`. Community LocalStack still provides Secrets Manager, S3, and DynamoDB. Docker-backed EC2 and ELBv2 stay off (they are Pro). `make up` then runs the app container via `scripts/run-app-local.sh` so `/debug/secret-source` still shows a Secrets Manager ARN.

## 3. Start LocalStack with Docker (this repo)

You must be on **Linux** with Docker Engine. From the repo:

```bash
export LOCALSTACK_AUTH_TOKEN='...'
make localstack-up
curl -s http://localhost:4566/_localstack/health | head
```

Compose file: `observability/docker-compose.localstack.yml`. It:

- publishes port **4566** (the AWS edge)
- mounts `/var/run/docker.sock` so LocalStack can start EC2 containers
- sets `EC2_DOCKER_FLAGS=--memory=512m` (the cgroup ceiling for incident 2204)

Official compose notes: https://docs.localstack.cloud/aws/getting-started/installation/#docker-compose

## 4. Dummy AWS keys (not secrets)

LocalStack accepts:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
```

These are **not** real AWS credentials. Account id is `000000000000`. Do not confuse them with the Aiven DB password.

Optional CLI wrapper: https://docs.localstack.cloud/aws/tooling/aws-cli/ (`awslocal`).

## 5. GitHub Actions

CI must start LocalStack **in the runner** (`LocalStack/setup-localstack`), not a hosted ephemeral instance.

Add the same Hobby token as repository secret `LOCALSTACK_AUTH_TOKEN`. See [GitHub secrets](github-secrets.md).

Official Actions guide: https://docs.localstack.cloud/aws/integrations/continuous-integration/github-actions/

## 6. Next

[Aiven MySQL](aiven-mysql.md)
