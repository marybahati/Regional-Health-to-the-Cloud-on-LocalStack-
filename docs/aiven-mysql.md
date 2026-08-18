# Aiven for MySQL (free managed database)

The original plan used **AWS RDS on LocalStack**. RDS is **not** on the LocalStack free Hobby tier, and nobody should pay for this lab. We use **Aiven for MySQL** instead: a real managed MySQL, free forever.

Everything else stays the same: Secrets Manager, EC2, scanning gates, pipeline. Terraform **does not create a database**. It **writes your Aiven connection details into Secrets Manager**. The app calls `GetSecretValue` at boot, same as the brief.

If you saw **ECR** in an earlier version, ignore it. ECR is also not on the free tier. The image is built and scanned in the pipeline and used directly.

Official Aiven docs:

- Console: https://console.aiven.io/
- MySQL get started: https://aiven.io/docs/products/mysql/get-started
- Connect to MySQL: https://aiven.io/docs/products/mysql/howto/connect-with-mysql-cli
- TLS / CA certificate: https://aiven.io/docs/tools/cli/service/connection-info
- Free plans: https://aiven.io/pricing

## Before you click anything

- Use **your own personal** Aiven account. The free tier is **one MySQL per account**. Do not share a service across the group.
- No credit card for the free plan.
- The free service **goes to sleep when idle**. Open it in the console (or run one query) to wake it before `make up` or CI.
- Limits (1 GB storage, 76 connections) are enough for 10,000 seed rows and this lab.

## 1. Sign up (~1 minute)

1. Open https://console.aiven.io/ and create a free account.
2. Confirm your email if asked.

## 2. Create a free MySQL service (~2 minutes)

1. In the console, **Create service**.
2. Choose **MySQL**.
3. Choose the **Free** plan.
4. Pick any region close to you.
5. Name it something like `service-a-mysql` (this is your Aiven service name, not the Node app).
6. Create it and wait until the status is **Running** (a minute or two).

If it says sleeping later: open the service page; it will wake up.

## 3. Copy connection details

On the service **Overview** page you will see connection info. You need:

| Field | Typical value | Where it goes |
|---|---|---|
| Host | `something.a.aivencloud.com` | `AIVEN_MYSQL_HOST` / `TF_VAR_db_host` |
| Port | a number, often `12345` (not 3306) | `AIVEN_MYSQL_PORT` / `TF_VAR_db_port` |
| User | `avnadmin` | `AIVEN_MYSQL_USER` / `TF_VAR_db_username` |
| Password | long random string | `AIVEN_MYSQL_PASSWORD` / `TF_VAR_db_password` |
| Database | often `defaultdb` | `AIVEN_MYSQL_DB` / `TF_VAR_db_name` |
| CA certificate | `ca.pem` download | `AIVEN_CA_PATH` or `TF_VAR_db_ca_cert` |

**Download the CA certificate.** Aiven requires TLS. Without the CA, connections fail.

Official “how to connect”: https://aiven.io/docs/products/mysql/howto/connect-with-mysql-cli

## 4. Put values in your local environment (never git)

On Linux / in the VM, in the repo:

```bash
cp .env.example .env
```

Edit `.env` (this file is gitignored):

```bash
AIVEN_MYSQL_HOST=your-host.a.aivencloud.com
AIVEN_MYSQL_PORT=12345
AIVEN_MYSQL_USER=avnadmin
AIVEN_MYSQL_PASSWORD=paste-password
AIVEN_MYSQL_DB=defaultdb
AIVEN_CA_PATH=$PWD/ca.pem
```

Save the downloaded CA as `ca.pem` in the repo root. `*.pem` is gitignored.

Load them:

```bash
set -a
source .env
set +a

# Terraform reads TF_VAR_* automatically
export TF_VAR_db_host="$AIVEN_MYSQL_HOST"
export TF_VAR_db_port="$AIVEN_MYSQL_PORT"
export TF_VAR_db_username="$AIVEN_MYSQL_USER"
export TF_VAR_db_password="$AIVEN_MYSQL_PASSWORD"
export TF_VAR_db_name="$AIVEN_MYSQL_DB"
export TF_VAR_db_ca_cert="$(cat "$AIVEN_CA_PATH")"
```

`make up` also maps these if you sourced `.env`.

Quick check that Aiven is awake (from Linux, with `mysql` client):

```bash
mysql --host="$AIVEN_MYSQL_HOST" --port="$AIVEN_MYSQL_PORT" \
  --user="$AIVEN_MYSQL_USER" --password="$AIVEN_MYSQL_PASSWORD" \
  --ssl-mode=REQUIRED --ssl-ca="$AIVEN_CA_PATH" \
  "$AIVEN_MYSQL_DB" -e 'SELECT 1;'
```

If this hangs, the service is probably asleep — open it in the Aiven console and retry.

## 5. Same values as GitHub Actions secrets

CI cannot see your laptop `.env`. Add the secrets listed in [GitHub secrets](github-secrets.md).

Terraform in CI writes them into **LocalStack Secrets Manager**. The running app never reads GitHub secrets; it only reads the ARN from user-data and then `GetSecretValue`.

## What you must never do

- Do not commit `.env`, `ca.pem`, `terraform.tfvars`, or a screenshot of the password.
- Do not put the password in user-data, the Docker image, or the README.
- Do not share one Aiven service with the whole group.

## Next

[GitHub secrets](github-secrets.md) then [first run](first-run.md).
