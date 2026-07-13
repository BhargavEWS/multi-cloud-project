terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Not applied yet (see infra/aws/README.md). Once you have an AWS account,
  # point this at its own state bucket, e.g.:
  # backend "s3" {
  #   bucket = "<your-account>-tfstate"
  #   key    = "multicloud-gitops-platform/aws/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region
}
