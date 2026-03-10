data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "platform/ecs/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "platform/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

terraform {
  backend "s3" {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "clients/etcd/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "gateway" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "clients/gateway/terraform.tfstate"
    region = var.aws_region
  }
}
