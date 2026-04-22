#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./bootstrap_scripts.sh [bucket_name] [region] [lock_table_name]
# Example:
#   ./bootstrap_scripts.sh terragrunt-learning-bucket eu-central-1 terraform-locks

BUCKET_NAME="${1:-terragrunt-learning-bucket}"
AWS_REGION="${2:-eu-central-1}"
LOCK_TABLE_NAME="${3:-terraform-locks}"

EXPECTED_ACCOUNT_ID="${EXPECTED_ACCOUNT_ID:-111111111111}"
AWS_PROFILE="${AWS_PROFILE:-my-dev-profile}"

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI is not installed or not in PATH." >&2
  exit 1
fi

CURRENT_ACCOUNT_ID="$(aws sts get-caller-identity \
  --profile "${AWS_PROFILE}" \
  --query Account \
  --output text)"

if [[ "${CURRENT_ACCOUNT_ID}" != "${EXPECTED_ACCOUNT_ID}" ]]; then
  echo "ERROR: wrong AWS account. Expected ${EXPECTED_ACCOUNT_ID}, got ${CURRENT_ACCOUNT_ID}" >&2
  exit 1
fi

echo "Creating DynamoDB lock table: ${LOCK_TABLE_NAME} (region: ${AWS_REGION})"
aws dynamodb create-table \
  --table-name "${LOCK_TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}"

echo "Creating S3 bucket: ${BUCKET_NAME} (region: ${AWS_REGION})"
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${AWS_REGION}" \
  --create-bucket-configuration "LocationConstraint=${AWS_REGION}"

echo "Enabling versioning"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "Setting default bucket encryption (SSE-S3)"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Blocking all public access"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Done."
