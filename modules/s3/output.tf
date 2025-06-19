# terraform/modules/s3/outputs.tf
output "buckets" {
  description = "S3 bucket details"
  value = {
    for k, v in aws_s3_bucket.buckets : k => {
      id     = v.id
      arn    = v.arn
      domain = v.bucket_domain_name
      region = v.region
    }
  }
}

output "bucket_names" {
  description = "S3 bucket names"
  value       = [for bucket in aws_s3_bucket.buckets : bucket.id]
}

output "bucket_arns" {
  description = "S3 bucket ARNs"
  value       = [for bucket in aws_s3_bucket.buckets : bucket.arn]
}