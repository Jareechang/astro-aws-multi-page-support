# Infrastructure definitions

provider "aws" {
  version = "~> 4.24.0"
  region  = var.aws_region
}

locals {
  min_ttl = 0
  max_ttl = 86400
  default_ttl = 3600

  s3_origin_id = "astro-static-site"
}

resource "aws_s3_bucket" "site_asset_bucket" {
  bucket            = "static-site-assets-1234"
}

resource "aws_s3_bucket_acl" "site_asset_bucket_acl" {
  bucket = aws_s3_bucket.site_asset_bucket.id
  acl    = "private"
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

### Github OIDC for accessing AWS resources (ie S3)
resource "aws_iam_openid_connect_provider" "github_actions" {
  client_id_list  = var.client_id_list
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  url             = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
        format(
          "arn:aws:iam::%s:root",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        format(
          "arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repo_name}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.site_asset_bucket.arn,
      "${aws_s3_bucket.site_asset_bucket.arn}/*"
    ]
  }
  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    effect = "Allow"
    resources = [
      aws_cloudfront_distribution.cf_distribution.arn
    ]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "CF origin identity"
}

data "aws_iam_policy_document" "cf_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontS3Access"
    actions   = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.site_asset_bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.oai.iam_arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_allow_access" {
  bucket = aws_s3_bucket.site_asset_bucket.id
  policy = data.aws_iam_policy_document.cf_bucket_policy.json
}

resource "aws_cloudfront_function" "cf_viewer" {
  name    = "astro-multi-page-cf-viewer-function"
  runtime = "cloudfront-js-1.0"
  comment = "Remap paths to index.html when request origin for multi-page sites"
  publish = true
  code    = file("../functions/viewer-request/index.js")
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name = aws_s3_bucket.site_asset_bucket.bucket_regional_domain_name
    origin_id = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.oai.id}"
    }
  }

  enabled = true
  is_ipv6_enabled     = true
  comment             = "Astro static site CF"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = local.min_ttl
    default_ttl            = local.default_ttl
    max_ttl                = local.max_ttl
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.cf_viewer.arn
    }
  }

  # Redirect all navigation outside of expected to home
  custom_error_response {
    error_caching_min_ttl = 0
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  price_class = var.cf_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
