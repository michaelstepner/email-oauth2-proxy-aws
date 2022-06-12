terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.4.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.9.0"
    }
  }

  required_version = "~> 1.2.2"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "acme" {
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
