terraform {
  required_version = ">= 1.13.0"

  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0"
    }
  }
}
