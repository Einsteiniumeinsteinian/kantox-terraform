#!/bin/bash
set -e
# === Configurable Variables with Defaults ===
REGION="${REGION:-us-west-2}"
BUCKET_NAME="${BUCKET_NAME:-my-terraform-state-bucket-124356}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-terraform-locks}"
PROFILE="${PROFILE:-default}" # Optional AWS CLI profile

# === Confirm ===
echo "⚠️  You are about to destroy the Terraform backend:"
echo "    - S3 Bucket: $BUCKET_NAME"
echo "    - DynamoDB Table: $DYNAMODB_TABLE"
echo "    - Region: $REGION"
echo
read -p "Are you sure? This CANNOT be undone (yes/[no]): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# === Delete all objects from the S3 bucket ===
echo "Emptying S3 bucket: $BUCKET_NAME ..."
aws s3 rm "s3://$BUCKET_NAME" --recursive --region "$REGION" --profile "$PROFILE"

# === Delete the S3 bucket ===
echo "Deleting S3 bucket..."
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION" --profile "$PROFILE"

# === Delete the DynamoDB table ===
echo "Deleting DynamoDB table: $DYNAMODB_TABLE ..."
aws dynamodb delete-table \
  --table-name "$DYNAMODB_TABLE" \
  --region "$REGION" \
  --profile "$PROFILE"

echo
echo "✅ Terraform backend resources have been destroyed."
