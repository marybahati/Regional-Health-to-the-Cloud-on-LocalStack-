SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help
export PATH := $(HOME)/.local/bin:$(PATH)
SERVICE ?= service-a
ROOT := terraform/environments/$(SERVICE)
COMPOSE_LS := docker compose -f observability/docker-compose.localstack.yml
COMPOSE_OBS := docker compose -f observability/docker-compose.yml
IMAGE := $(SERVICE):local
export ROOT
export SERVICE
export APP_CONTAINER_NAME ?= $(SERVICE)-e2e
export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION ?= us-east-1
export AWS_ENDPOINT_URL ?= http://localhost:4566
export S3_HOSTNAME ?= localhost
export EC2_DOCKER_FLAGS ?= --memory=512m

.PHONY: help up down verify fmt validate lint seed evidence ami \
        localstack-up localstack-down apply destroy plan-empty \
        obs-up health-degraded run-app

help: ## Show targets.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Stand the $(SERVICE) stack up from zero on a clean LocalStack (SERVICE=service-a|service-b|service-c).
	set -a; [ -f .env ] && . ./.env; set +a
	@. scripts/ls-mode.sh
	@. scripts/aiven-tf-env.sh
	$(MAKE) localstack-up
	$(MAKE) ami
	TF_STATE_BUCKET=rh-tfstate-$(SERVICE) ./scripts/bootstrap-state.sh
	$(MAKE) apply
	$(MAKE) seed
	@if [ "$${TF_VAR_enable_compute:-true}" = "false" ]; then \
	  ROOT=$(ROOT) APP_CONTAINER_NAME=$(SERVICE)-e2e IMAGE=$(IMAGE) SERVICE_NAME=$(SERVICE) ./scripts/run-app-local.sh; \
	fi
	$(MAKE) obs-up
	$(MAKE) verify
	@echo "make up complete — $(SERVICE) is green."

down: ## Destroy the stack and stop LocalStack.
	-$(MAKE) destroy
	$(COMPOSE_OBS) down -v || true
	$(COMPOSE_LS) down -v || true

localstack-up: ## Start LocalStack (Hobby / in-process, not ephemeral).
	set -a; [ -f .env ] && . ./.env; set +a
	. scripts/ls-mode.sh
	$(COMPOSE_LS) up -d
	@echo "waiting for LocalStack..."
	@for i in $$(seq 1 60); do \
	  curl -sf http://localhost:4566/_localstack/health >/dev/null && exit 0; \
	  sleep 2; \
	done; echo "LocalStack did not become healthy"; exit 1

localstack-down:
	$(COMPOSE_LS) down -v

ami: ## Build, scan-friendly image, tag as localstack-ec2/app:ami-<sha12>.
	@test -f api/package-lock.json || (cd api && npm install --package-lock-only)
	docker build -f api/Dockerfile -t $(IMAGE) .
	SHA12=$$(git rev-parse --short=12 HEAD 2>/dev/null || echo 0123456789ab); \
	  docker tag $(IMAGE) localstack-ec2/app:ami-$$SHA12; \
	  echo ami-$$SHA12 | tee .ami-id; \
	  echo "tagged localstack-ec2/app:ami-$$SHA12"

apply: ## tflocal apply the $(SERVICE) root.
	@. scripts/ls-mode.sh
	@. scripts/aiven-tf-env.sh
	tflocal -chdir=$(ROOT) init -input=false -reconfigure
	tflocal -chdir=$(ROOT) apply -auto-approve -input=false -var="app_ami_id=$$(cat .ami-id)" | tee evidence/01-iac/apply.log
	$(MAKE) plan-empty

plan-empty: ## Evidence: terraform plan after apply must be empty.
	. scripts/ls-mode.sh
	. scripts/aiven-tf-env.sh
	tflocal -chdir=$(ROOT) plan -detailed-exitcode -var="app_ami_id=$$(cat .ami-id)" > evidence/01-iac/plan-after-apply.txt || { \
	  code=$$?; \
	  if [ $$code -eq 2 ]; then echo "plan was not empty"; cat evidence/01-iac/plan-after-apply.txt; exit 1; fi; \
	  exit $$code; \
	}
	@echo "plan after apply is empty"

destroy: ## Destroy and capture evidence/01-iac/destroy.log.
	@. scripts/ls-mode.sh
	@. scripts/aiven-tf-env.sh
	-docker rm -f $(SERVICE)-e2e >/dev/null 2>&1 || true
	tflocal -chdir=$(ROOT) destroy -auto-approve -input=false -var="app_ami_id=$$(cat .ami-id)" | tee evidence/01-iac/destroy.log

seed: ## Schema + 10k patients on Aiven (count is a terraform variable).
	@. scripts/ls-mode.sh
	@. scripts/aiven-tf-env.sh
	./scripts/seed-db.sh | tee evidence/02-data/seed.log
	@grep -E 'patient_count|already have|seed complete' evidence/02-data/seed.log | tail -n 8 | tee evidence/02-data/row-counts.txt

obs-up: ## Prometheus / Grafana / Alertmanager (pre-wired + four incident rules).
	@find observability -name "._*" -delete 2>/dev/null || true
	@mkdir -p observability/targets
	@HOSTPORT=$$(ROOT=$(ROOT) ./scripts/instance-url.sh | sed -E 's#https?://##'); \
	  printf '[{"targets":["%s"],"labels":{"job":"capacity-api","service":"%s"}}]\n' "$$HOSTPORT" "$(SERVICE)" \
	  > observability/targets/$(SERVICE).json
	$(COMPOSE_OBS) up -d

verify: ## Grader command. Non-zero if health, plan, secrets, or gitleaks fail.
	./scripts/verify.sh

health-degraded: ## C4 artifact: break secret → /readyz 503 → nginx 503 → restore.
	./scripts/readyz-degraded.sh evidence/04-health/readyz-degraded.txt

fmt: ## terraform fmt
	terraform fmt -recursive terraform

validate: ## terraform validate via tflocal
	tflocal -chdir=$(ROOT) validate

lint: ## tflint
	cd $(ROOT) && tflint --recursive || tflint
