terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17.1"
    }
  }

  required_version = "~> 1.2.2"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
