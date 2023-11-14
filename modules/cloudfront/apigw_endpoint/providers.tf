terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
      configuration_aliases = [
        aws.east
      ]
    }
  }
}
