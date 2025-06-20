#!/bin/bash
set -e

# === Configurable ===
SECRET_NAME="${SECRET_NAME:-terraform.tfvars}"
REGION="${REGION:-us-west-2}"
PROFILE="${PROFILE:-default}"
TF_ROOT_DIR="$(dirname "$0")/.."  # Terraform root relative to script dir

echo "🔐 Fetching terraform.tfvars from Secrets Manager..."
TFVARS_CONTENT=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query 'SecretString' \
  --output text)

# === Go to Terraform root directory ===
cd "$TF_ROOT_DIR"

# === Init backend ===
echo "🚀 Running terraform init..."
terraform init

# === Prompt for confirmation ===
echo
echo "⚠️  You are about to destroy all Terraform-managed infrastructure!"
read -p "Are you sure you want to continue? (yes/[no]): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# === Run terraform destroy with tfvars from secret ===
echo "🔥 Destroying infrastructure..."
terraform destroy -var-file=<(echo "$TFVARS_CONTENT") --auto-approve
