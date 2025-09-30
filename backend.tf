terraform {
  backend "s3" {
    bucket       = "fd-jai-tf-state-91733293"
    key          = "feeders/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
  }
}
