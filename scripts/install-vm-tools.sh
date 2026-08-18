#!/usr/bin/env bash
# Tooling inside the Linux VM (not the Mac).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y curl unzip python3 python3-pip mysql-client jq make ca-certificates gnupg
if ! command -v terraform >/dev/null; then
  curl -sSfL https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_arm64.zip -o /tmp/tf.zip
  sudo unzip -o /tmp/tf.zip -d /usr/local/bin
fi
python3 -m pip install --user terraform-local
if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
if ! command -v k6 >/dev/null; then
  sudo gpg -k
  curl -sSfL https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
  sudo apt-get update && sudo apt-get install -y k6 || true
fi
if ! command -v gitleaks >/dev/null; then
  curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_arm64.tar.gz \
    | sudo tar -xz -C /usr/local/bin gitleaks
fi
echo "tools ready: terraform=$(terraform version | head -1) node=$(node -v) docker=$(docker version --format '{{.Server.Version}}')"
