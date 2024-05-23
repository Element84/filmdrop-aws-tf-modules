terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  required_version = ">= 1.6.6, < 1.9.0"

}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_service_linked_role" "opensearch_linked_role" {
  aws_service_name = "opensearchservice.amazonaws.com"
}
