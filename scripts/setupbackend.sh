#!/bin/bash

set -e

# === Configurable Variables with Defaults ===
REGION="${REGION:-us-west-2}"
BUCKET_NAME="${BUCKET_NAME:-my-terraform-state-bucket-124356}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-terraform-locks}"
PROFILE="${PROFILE:-default}" # Optional: set via env
TF_ROOT_DIR="$(dirname "$0")/.."  # Adjust if your root is elsewhere

BACKEND_FILE="$TF_ROOT_DIR/backend.tf"

# === Create S3 bucket ===
echo "Creating S3 bucket: $BUCKET_NAME in region: $REGION ..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" \
  --profile "$PROFILE" || echo "⚠️ Bucket may already exist."

# === Enable versioning on S3 bucket ===
echo "Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$PROFILE"

# === Create DynamoDB table for state locking ===
echo "Creating DynamoDB table: $DYNAMODB_TABLE ..."
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region "$REGION" \
  --profile "$PROFILE" || echo "⚠️ Table may already exist."

echo "Waiting for DynamoDB table to become active..."
aws dynamodb wait table-exists \
  --table-name "$DYNAMODB_TABLE" \
  --region "$REGION" \
  --profile "$PROFILE"

# === Write backend config block to backend.tf ===
echo "Writing backend config to $BACKEND_FILE ..."
cat > "$BACKEND_FILE" <<EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo
echo "✅ Terraform backend is set up and written to $BACKEND_FILE."
