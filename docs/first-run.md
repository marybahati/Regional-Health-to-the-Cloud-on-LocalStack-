# First run (Service A)

You should already have:

- Linux (native or [VM](setup-vm.md))
- Docker Engine working
- [Aiven MySQL](aiven-mysql.md) running (wake it if it slept) and vars exported
- Optional: [LocalStack Hobby token](localstack.md) for Docker-backed EC2. Without it, `make up` uses community LocalStack (Secrets Manager + the app container on port 18080).

## Load environment

From the repo on **Linux**:

```bash
set -a
source .env
set +a
export PATH="$HOME/.local/bin:$PATH"
export TF_VAR_db_host="$AIVEN_MYSQL_HOST"
export TF_VAR_db_port="$AIVEN_MYSQL_PORT"
export TF_VAR_db_username="$AIVEN_MYSQL_USER"
export TF_VAR_db_password="$AIVEN_MYSQL_PASSWORD"
export TF_VAR_db_name="$AIVEN_MYSQL_DB"
export TF_VAR_db_ca_cert="$(cat "${AIVEN_CA_PATH:-./ca.pem}")"
```

## Stand it up

```bash
make up
```

That should, on a clean LocalStack:

1. Start LocalStack
2. Build the Service A image and tag it `localstack-ec2/app:ami-<12 hex chars>`
3. Create S3 + DynamoDB for Terraform state
4. Apply Terraform (Aiven envelope into Secrets Manager). With a Hobby token this also creates Docker-backed EC2 + nginx. **No RDS. No ECR.** Without a token, `scripts/run-app-local.sh` starts the same image and fetches the secret from LocalStack.
5. Seed 10,000 patients **on Aiven**
6. Start Prometheus / Grafana
7. Run `make verify`

## Check it yourself

```bash
make verify
URL=$(./scripts/instance-url.sh)
curl -sS "$URL/healthz"
curl -sS "$URL/readyz"
curl -sS "$URL/debug/secret-source"
```

`/debug/secret-source` must show a Secrets Manager ARN (not `env` / `TODO`) and a version id. It must **not** print the password.

## If it fails

| Symptom | Likely cause |
|---|---|
| RDS / EC2 “doesn’t exist” | `LOCALSTACK_AUTH_TOKEN` unset → community image |
| `InvalidAMIID.NotFound` | skipped `make ami` / tag is not `localstack-ec2/app:ami-<12 hex>` |
| `/readyz` 503, TLS errors | Aiven asleep, wrong CA, or password not in Terraform vars |
| Cannot curl the instance from a Mac | you used Docker Desktop; use the [Linux VM](setup-vm.md) |
| mysql hangs | open the Aiven service in the console to wake it |

## Stop

```bash
make down
```

That destroys LocalStack resources. **Aiven is not deleted** — it is your managed DB. Leave it running (it will sleep) or delete the service in the Aiven console if you are done.
