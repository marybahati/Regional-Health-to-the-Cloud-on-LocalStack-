#!/usr/bin/env bash
# Tag the scanned app image as a LocalStack Docker AMI.
set -euo pipefail
IMAGE="${1:?image name:tag}"
SHA12="$(echo -n "$IMAGE" | git rev-parse --short=12 HEAD)"
AMI_ID="ami-${SHA12}"
docker tag "$IMAGE" "localstack-ec2/app:${AMI_ID}"
echo "$AMI_ID"
