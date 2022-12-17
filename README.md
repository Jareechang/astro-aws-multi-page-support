# Astro with Amazon Cloudfront + S3 multi-page support 

Set up an automated CI/CD pipeline with Astro.

Link to tutorial - [Amazon S3 + Cloudfront: Multi-page suport (Tutorial)](https://www.jerrychang.ca/writing/amazon-s3-cloudfront-multi-page-support-tutorial).

# Technologies

- [Terraform](https://github.com/hashicorp/terraform)
- [Astro](https://astro.build/)
- AWS
  - Cloudfront
  - S3
- Github Actions 

# Getting started

## Running the site

**Folder:** `site/*`

1. Add a `.env` file
2. Add the unsplash API key (ie `UNSPLASH_API_KEY=xxxx`)
3. Run `pnpm dev` or `pnpm build` (`pnpm` can be swapped with `yarn` or `npm`)

## Applying the infrastructure

⚠️ Before you apply the infrastructure, update the "repo_name" in the `infra/variables.tf`.

This is so OIDC works with your Github Actions CI/CD if you choose to fork or clone this setup.

For more information, check the tutorial link.

**Run the following:**

```sh
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>
export AWS_DEFAULT_REGION=us-east-1

terraform init
terraform plan
terraform apply -auto-approve
```
