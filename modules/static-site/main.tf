terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "site" {
  force_destroy = true
  bucket = "${var.project_name}-${var.environment}-mysite-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "logs" {
  force_destroy = true
  bucket = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "site-oac-${var.environment}"
  description                       = "OAC for site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index-${var.environment}.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index-${var.environment}.html")
}

resource "aws_cloudfront_distribution" "site" {
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }
  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = "site"
  }


  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_regional_domain_name
    prefix          = "cloudfront/"
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 0
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 0
    response_code         = 200
    response_page_path    = "/index.html"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

data "aws_caller_identity" "current" {}

output "logs_bucket" {
  value = aws_s3_bucket.logs.id
}
output "bucket_name" {
  value = aws_s3_bucket.site.id
}
