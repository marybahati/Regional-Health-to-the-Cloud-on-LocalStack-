# GitHub Actions secrets

The scanners (gitleaks, trivy, zizmor) run with **no secrets**. Only the **deploy** job sees these.

Repo: **Settings → Secrets and variables → Actions → New repository secret**.

GitHub docs: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions

| Secret name | What it is | Where you got it |
|---|---|---|
| `LOCALSTACK_AUTH_TOKEN` | LocalStack Hobby token | [LocalStack](localstack.md) |
| `AIVEN_MYSQL_HOST` | MySQL hostname | Aiven Overview |
| `AIVEN_MYSQL_PORT` | MySQL port | Aiven Overview |
| `AIVEN_MYSQL_USER` | usually `avnadmin` | Aiven Overview |
| `AIVEN_MYSQL_PASSWORD` | MySQL password | Aiven Overview |
| `AIVEN_MYSQL_DB` | usually `defaultdb` | Aiven Overview |
| `AIVEN_MYSQL_CA` | full contents of `ca.pem` | Aiven “Download CA” |

Paste the **PEM text** (including `BEGIN CERTIFICATE`) into `AIVEN_MYSQL_CA`.

Do **not** add dummy `AWS_ACCESS_KEY_ID=test` as a GitHub secret. Those are hardcoded as LocalStack defaults in the workflow.

After they exist, a push/PR on `main` can run `.github/workflows/rehost-service-a.yml`.
