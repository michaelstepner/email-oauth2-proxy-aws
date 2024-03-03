terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.39.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.20.2"
    }
  }

  required_version = "= 1.5.7"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "acme" {
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
