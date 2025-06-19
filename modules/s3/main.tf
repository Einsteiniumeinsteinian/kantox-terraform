# terraform/modules/s3/main.tf
locals {
  prefix_dash = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash = var.name_suffix != "" ? "-${var.name_suffix}" : ""
}

resource "aws_s3_bucket" "buckets" {
  for_each = var.buckets
  
  bucket =  "${local.prefix_dash}${var.general_tags.Environment}-${each.key}-${var.general_tags.Project}${local.suffix_dash}"

  tags = merge(var.general_tags, {
    Name        = "${local.prefix_dash}${var.general_tags.Environment}-${each.key}-${var.general_tags.Project}${local.suffix_dash}"
    Purpose     = each.key
  })
}

resource "aws_s3_bucket_versioning" "buckets" {
  for_each = var.buckets
  
  bucket = aws_s3_bucket.buckets[each.key].id
  
  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = { for k, v in var.buckets : k => v if v.encryption }
  
  bucket = aws_s3_bucket.buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = var.buckets
  
  bucket = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
