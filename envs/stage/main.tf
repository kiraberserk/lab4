terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "lab-terraform-state-162557263015"
    key            = "stage/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "site" {
  source = "../../modules/static-site"

  project_name = "practice"
  environment  = "stage"
}

output "cloudfront_domain" {
  value = module.site.cloudfront_domain
}
