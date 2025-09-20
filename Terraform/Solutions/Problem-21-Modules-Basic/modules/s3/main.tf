# S3 Module - main.tf

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  count = var.versioning_enabled ? 1 : 0
  
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.server_side_encryption_configuration != null ? 1 : 0
  
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm
      kms_master_key_id = lookup(var.server_side_encryption_configuration.rule.apply_server_side_encryption_by_default, "kms_master_key_id", null)
    }
    bucket_key_enabled = lookup(var.server_side_encryption_configuration.rule, "bucket_key_enabled", null)
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "this" {
  count = var.public_access_block != null ? 1 : 0
  
  bucket = aws_s3_bucket.this.id

  block_public_acls       = lookup(var.public_access_block, "block_public_acls", false)
  block_public_policy     = lookup(var.public_access_block, "block_public_policy", false)
  ignore_public_acls      = lookup(var.public_access_block, "ignore_public_acls", false)
  restrict_public_buckets = lookup(var.public_access_block, "restrict_public_buckets", false)
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.lifecycle_configuration != null ? 1 : 0
  
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_configuration.rule
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          date                         = lookup(expiration.value, "date", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])
        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])
        content {
          noncurrent_days = lookup(noncurrent_version_transition.value, "days", null)
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tag", null) != null ? [filter.value.tag] : []
            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.cors_rule != null ? 1 : 0
  
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rule
    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "this" {
  count = var.website != null ? 1 : 0
  
  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = lookup(var.website, "index_document", null) != null ? [var.website.index_document] : []
    content {
      suffix = index_document.value.suffix
    }
  }

  dynamic "error_document" {
    for_each = lookup(var.website, "error_document", null) != null ? [var.website.error_document] : []
    content {
      key = error_document.value.key
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = lookup(var.website, "redirect_all_requests_to", null) != null ? [var.website.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = lookup(redirect_all_requests_to.value, "protocol", null)
    }
  }

  dynamic "routing_rule" {
    for_each = lookup(var.website, "routing_rule", [])
    content {
      dynamic "condition" {
        for_each = lookup(routing_rule.value, "condition", null) != null ? [routing_rule.value.condition] : []
        content {
          http_error_code_returned_equals = lookup(condition.value, "http_error_code_returned_equals", null)
          key_prefix_equals               = lookup(condition.value, "key_prefix_equals", null)
        }
      }

      redirect {
        host_name               = lookup(routing_rule.value.redirect, "host_name", null)
        http_redirect_code      = lookup(routing_rule.value.redirect, "http_redirect_code", null)
        protocol                = lookup(routing_rule.value.redirect, "protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.redirect, "replace_key_prefix_with", null)
        replace_key_with        = lookup(routing_rule.value.redirect, "replace_key_with", null)
      }
    }
  }
}
