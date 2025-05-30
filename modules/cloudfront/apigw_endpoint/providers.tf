terraform {
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22"
      configuration_aliases = [
        aws.east
      ]
    }
  }
}
