#!/bin/bash

set -e
cd "$(dirname "$0")/.."
# === Configurable ===
SECRET_NAME="${SECRET_NAME:-terraform.tfvars}"
REGION="${REGION:-us-west-2}"
PROFILE="${PROFILE:-default}"

# === Run Terraform Init ===
echo "🚀 Running terraform init..."
terraform init
echo "📦 Planning Terraform using secret from AWS Secrets Manager..."
terraform plan -var-file=<(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query 'SecretString' \
  --output text)

# === Run Terraform Apply using secret from Secrets Manager (no file) ===
echo "📦 Applying Terraform using secret from AWS Secrets Manager..."
terraform apply -var-file=<(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query 'SecretString' \
  --output text) \
  --auto-approve
