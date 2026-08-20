terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "site" {
  source = "../../modules/static-site"

  project_name = "practice"
  environment  = "devel"
}

output "cloudfront_domain" {
  value = module.site.cloudfront_domain
}
