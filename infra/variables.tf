# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "client_id_list" {
  default = [
    "sts.amazonaws.com"
  ]
}

variable "repo_name" {
  type    = string
  # Change this to your Github repository name 👇
  default = "Jareechang/astro-aws-multi-page-support"
}

variable "cf_price_class" {
  default = "PriceClass_100"
}
