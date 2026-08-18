# Native Linux setup

Use this page if your computer **already runs Linux**. If you are on a Mac, stop and go to [Linux VM setup](setup-vm.md).

## What you need

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores |
| RAM | 8 GB | 16 GB |
| Disk | 32 GB free | 32 GB |
| OS | Ubuntu 22.04 / 24.04 (or similar) | same |
| Account | Free [LocalStack](https://app.localstack.cloud/) + free [Aiven](https://console.aiven.io/) | personal accounts, not shared |

You will install: Git, Make, Docker Engine (not Docker Desktop), curl, unzip, Python 3.

## 1. Update the system and install basics

**Ubuntu / Debian:**

```bash
sudo apt-get update
sudo apt-get install -y git make curl unzip python3 python3-pip python3-venv jq mysql-client
```

Confirm:

```bash
git --version
make --version
python3 --version
```

## 2. Install Docker Engine

Do **not** install Docker Desktop on Linux for this lab. Install **Docker Engine** so containers share a real Linux bridge (LocalStack EC2 needs that).

Official guide (pick your distro): https://docs.docker.com/engine/install/

**Ubuntu (convenience script is fine for a personal lab machine):**

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
```

Log out and back in (or run `newgrp docker`) so your user can talk to Docker without `sudo`.

```bash
docker version
docker compose version
docker run --rm hello-world
```

If `hello-world` prints a hello message, Docker works.

## 3. Install Terraform and tflocal

Terraform is the tool that creates AWS-shaped resources. `tflocal` is LocalStack’s wrapper so those commands hit `localhost:4566` instead of real AWS.

- Terraform installs: https://developer.hashicorp.com/terraform/install
- tflocal: https://docs.localstack.cloud/aws/tooling/terraform/

```bash
# Terraform 1.9.x (example for linux amd64 — use the arm64 zip on Apple Silicon VMs / Graviton)
curl -sSfL https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip -o /tmp/tf.zip
sudo unzip -o /tmp/tf.zip -d /usr/local/bin
terraform version

# tflocal (Python app — use pipx so you do not break system Python)
sudo apt-get install -y pipx
pipx ensurepath
pipx install terraform-local
tflocal -help | head
```

On **ARM** Linux (Raspberry Pi, some VMs, Lima on Apple Silicon) use `terraform_1.9.8_linux_arm64.zip` instead.

## 4. Clone this repo

```bash
cd ~
git clone https://github.com/marybahati/Regional-Health-to-the-Cloud-on-LocalStack-.git
cd Regional-Health-to-the-Cloud-on-LocalStack-
```

## 5. Next

1. [Set up LocalStack](localstack.md)
2. [Set up Aiven MySQL](aiven-mysql.md)
3. [First run](first-run.md)
