# Start here

You do **not** need to know AWS, Terraform, or Docker yet. Follow the pages in order.

This lab rehosts **Service A** onto a cloud-shaped stack. Two things are not on LocalStack’s free Hobby plan, so we do **not** use them:

| Dropped | Replacement |
|---|---|
| AWS RDS on LocalStack | [Aiven for MySQL](https://aiven.io/) (free forever, real managed MySQL) |
| Amazon ECR | Image is built and scanned **in the pipeline** and tagged as a LocalStack AMI. No registry. |

Everything else stays: Secrets Manager, EC2 (Docker-backed), scanning gates, CI.

## Why Linux?

LocalStack’s “EC2 instances” are Docker containers on a Linux bridge network. **macOS Docker Desktop cannot reach them.** That is a [LocalStack limitation](https://docs.localstack.cloud/aws/services/ec2/), not a bug in this repo.

Pick **one** machine path:

| Your laptop | What to do |
|---|---|
| You already have Linux (Ubuntu, Fedora, …) | [Native Linux setup](setup-linux.md) |
| You are on a **Mac** (or Windows) | [Linux VM setup](setup-vm.md) — we use Lima on macOS |
| You want zero local install | GitHub Codespaces (`.devcontainer/` in this repo) — still Linux inside |

Then:

1. [LocalStack (Hobby token + Docker)](localstack.md)
2. [Aiven MySQL (free managed database)](aiven-mysql.md)
3. [GitHub secrets](github-secrets.md) so CI can run
4. [First run (`make up`)](first-run.md)

## Official documentation (bookmark these)

- LocalStack getting started: https://docs.localstack.cloud/aws/getting-started/
- LocalStack auth tokens: https://docs.localstack.cloud/aws/getting-started/auth-token/
- LocalStack EC2 (Docker-backed instances): https://docs.localstack.cloud/aws/services/ec2/
- LocalStack + Terraform (`tflocal`): https://docs.localstack.cloud/aws/tooling/terraform/
- LocalStack GitHub Actions: https://docs.localstack.cloud/aws/integrations/continuous-integration/github-actions/
- Aiven MySQL quick start: https://aiven.io/docs/products/mysql/get-started
- Aiven free plans: https://aiven.io/pricing
- Docker Engine on Linux: https://docs.docker.com/engine/install/
- Lima (Linux VMs on macOS): https://lima-vm.io/
