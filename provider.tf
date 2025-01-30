terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "4.46.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "aws" {
  region = var.aws_region
}