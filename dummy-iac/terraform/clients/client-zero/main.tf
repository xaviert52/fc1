terraform {
  backend "s3" {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "clients/client-zero/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Estado de la Red
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "platform/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Estado del Cluster ECS
data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "platform/ecs/terraform.tfstate"
    region = var.aws_region
  }
}

# Buscamos el Security Group del Gateway para permitirle paso
# Asumimos que el SG del Gateway tiene el tag component = gateway
data "terraform_remote_state" "gateway" {
  backend = "s3"
  config = {
    bucket = "zerotrust-iac-tfstate-us-east-1"
    key    = "clients/gateway/terraform.tfstate"
    region = var.aws_region
  }
}
