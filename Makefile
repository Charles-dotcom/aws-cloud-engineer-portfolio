SHELL := bash
.SHELLFLAGS := -euo pipefail -c

.DEFAULT_GOAL := help

export TF_PLUGIN_CACHE_DIR := $(CURDIR)/.terraform.d/plugin-cache

TF_ROOTS := infrastructure/bootstrap \
	infrastructure/environments/dev \
	infrastructure/environments/staging \
	infrastructure/environments/prod

TF_TESTS := infrastructure/modules/vpc \
	infrastructure/modules/security-groups \
	infrastructure/modules/rds \
	infrastructure/modules/workload \
	infrastructure/modules/ci-policies

.PHONY: help fmt fmt-check validate lint test python-test terraform-test security check

help:
	@printf '%s\n' \
		'fmt          Format Terraform' \
		'fmt-check    Fail if Terraform is unformatted' \
		'validate     Init without a backend and validate every root module' \
		'lint         Run tflint' \
		'test         Run terraform test and the API unit tests' \
		'security     Run Trivy, Checkov and gitleaks' \
		'check        fmt-check, validate, lint, test and security'

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive

validate:
	@mkdir -p "$(TF_PLUGIN_CACHE_DIR)"
	@for dir in $(TF_ROOTS); do \
		echo "==> $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false -no-color; \
		terraform -chdir=$$dir validate -no-color; \
	done

lint:
	tflint --init --config=$(CURDIR)/.tflint.hcl
	tflint --recursive --config=$(CURDIR)/.tflint.hcl --chdir=$(CURDIR)/infrastructure

python-test: .venv/bin/pytest
	.venv/bin/pytest apps/api/tests -q

.venv/bin/pytest:
	python3 -m venv .venv
	.venv/bin/pip install -q -r apps/api/requirements-dev.txt 'checkov==3.3.30'

terraform-test:
	@mkdir -p "$(TF_PLUGIN_CACHE_DIR)"
	@# ci-policies renders IAM JSON locally. Dummy keys satisfy the provider
	@# when the shell has no AWS credentials. Real keys are left as they are.
	@export AWS_ACCESS_KEY_ID="$${AWS_ACCESS_KEY_ID:-test}"; \
	export AWS_SECRET_ACCESS_KEY="$${AWS_SECRET_ACCESS_KEY:-test}"; \
	export AWS_EC2_METADATA_DISABLED=true; \
	for dir in $(TF_TESTS); do \
		echo "==> $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false -no-color; \
		terraform -chdir=$$dir test -no-color; \
	done

test: python-test terraform-test

security: .venv/bin/pytest
	trivy config infrastructure --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform
	trivy fs apps --scanners vuln --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .venv
	.venv/bin/checkov -d infrastructure --framework terraform --compact --quiet --download-external-modules false
	gitleaks detect --source . --redact --config .gitleaks.toml --exit-code 1

check: fmt-check validate lint test security
