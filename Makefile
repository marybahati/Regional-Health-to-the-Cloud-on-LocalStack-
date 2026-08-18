SERVICE ?= service-b
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ENV_DIR := $(ROOT)terraform/environments/$(SERVICE)
GIT_SHA := $(shell git -C $(ROOT) rev-parse HEAD 2>/dev/null || echo localdev000000)
AMI_TAG := localstack-ec2/$(SERVICE):ami-$(shell echo $(GIT_SHA) | cut -c1-12)
IMAGE_NAME := rehost-$(SERVICE):local
NGINX_URL ?=

export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION ?= us-east-1

.PHONY: bootstrap up verify destroy fmt validate image tag

bootstrap:
	cd $(ROOT)terraform/bootstrap && tflocal init && tflocal apply -auto-approve

image:
	docker build -f $(ROOT)api/Dockerfile -t $(IMAGE_NAME) $(ROOT)

tag: image
	docker tag $(IMAGE_NAME) $(AMI_TAG)
	@echo "Tagged $(AMI_TAG)"

up: tag
	@test -n "$$LOCALSTACK_AUTH_TOKEN" || (echo "LOCALSTACK_AUTH_TOKEN is required" && exit 1)
	@test -n "$$AIVEN_MYSQL_HOST" || (echo "AIVEN_MYSQL_HOST is required" && exit 1)
	@test -n "$$AIVEN_MYSQL_PASSWORD" || (echo "AIVEN_MYSQL_PASSWORD is required" && exit 1)
	cd $(ENV_DIR) && tflocal init && \
	TF_VAR_app_ami_id=$(AMI_TAG) \
	TF_VAR_db_host=$$AIVEN_MYSQL_HOST \
	TF_VAR_db_port=$${AIVEN_MYSQL_PORT:-3306} \
	TF_VAR_db_username=$${AIVEN_MYSQL_USER:-avnadmin} \
	TF_VAR_db_password=$$AIVEN_MYSQL_PASSWORD \
	tflocal apply -auto-approve
	@$(MAKE) -C $(ROOT) verify SERVICE=$(SERVICE)

verify:
	@command -v tflocal >/dev/null || (echo "install tflocal: pip install terraform-local" && exit 1)
	cd $(ENV_DIR) && tflocal plan -detailed-exitcode
	@url=$$(cd $(ENV_DIR) && tflocal output -raw nginx_url 2>/dev/null); \
	if [ -z "$$url" ]; then url="$(NGINX_URL)"; fi; \
	test -n "$$url" || (echo "Set NGINX_URL or apply terraform first" && exit 1); \
	curl -fsS "$$url/healthz" >/dev/null; \
	curl -fsS "$$url/readyz" >/dev/null; \
	curl -fsS "$$url/debug/secret-source" | grep -q arn; \
	if command -v gitleaks >/dev/null; then gitleaks detect --source $(ROOT) --no-banner; fi; \
	echo "verify passed for $$url"

destroy:
	mkdir -p $(ROOT)evidence/01-iac
	cd $(ENV_DIR) && tflocal destroy -auto-approve | tee $(ROOT)evidence/01-iac/destroy.log

fmt:
	terraform fmt -recursive $(ROOT)terraform

validate:
	cd $(ENV_DIR) && terraform init -backend=false && terraform validate
