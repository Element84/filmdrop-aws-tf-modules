terraform {
  required_version = ">= 1.6.6, < 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}