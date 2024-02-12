terraform {
  required_version = ">= 1.6.6, < 1.8.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
