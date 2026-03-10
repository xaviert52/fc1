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

data "terraform_remote_state" "etcd" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "clients/etcd/terraform.tfstate"
    region = var.aws_region
  }
}
