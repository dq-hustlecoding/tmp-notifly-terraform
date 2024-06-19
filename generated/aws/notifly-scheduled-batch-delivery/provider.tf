provider "aws" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }

  backend "s3" {
    bucket = "terraform-configuration-notifly-pfavx6b9"
    key    = "notifly-scheduled-batch-delivery-tfstate"
    region = "ap-northeast-2"
  }

  required_version = ">= 1.2.0"
}
