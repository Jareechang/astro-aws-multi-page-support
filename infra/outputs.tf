# Output value definitions

output "site_asset_bucket" {
  description = "Name of the S3 bucket used to store function code."
  value = aws_s3_bucket.site_asset_bucket.id
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "cf_distribution_domain_url" {
  value = "https://${aws_cloudfront_distribution.cf_distribution.domain_name}"
}

output "cf_distribution_id" {
  value = "${aws_cloudfront_distribution.cf_distribution.id}"
}
