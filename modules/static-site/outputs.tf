output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "logs_bucket" {
  value = aws_s3_bucket.logs.id
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}
