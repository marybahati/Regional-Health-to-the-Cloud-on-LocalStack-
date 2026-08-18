#!/usr/bin/env bash
# Create the S3 state bucket + DynamoDB lock table on LocalStack.
# Bucket is encrypted, versioned, and blocked from public access (prove with trivy config).
set -euo pipefail
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
BUCKET="${TF_STATE_BUCKET:-rh-tfstate-service-a}"
TABLE="${TF_LOCK_TABLE:-rh-tflock}"

aws --endpoint-url "$ENDPOINT" s3api create-bucket --bucket "$BUCKET" >/dev/null 2>&1 || true
aws --endpoint-url "$ENDPOINT" s3api put-bucket-versioning \
  --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws --endpoint-url "$ENDPOINT" s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
aws --endpoint-url "$ENDPOINT" s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws --endpoint-url "$ENDPOINT" dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null 2>&1 || true

echo "state backend ready: s3://$BUCKET  dynamodb://$TABLE"
