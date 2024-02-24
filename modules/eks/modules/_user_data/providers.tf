terraform {
  required_version = ">= 1.6.6, < 1.8.0"

  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0"
    }
  }
}
