terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.84.0"
      configuration_aliases = [aws]
    }
  }
  backend "s3" {
    bucket               = "aft-management-gitlab-runner-tfstate"
    key                  = "control-tower-scp.tfstate"
    region               = "eu-west-1"
    encrypt              = true
    use_lockfile         = true #S3 native locking
    workspace_key_prefix = "aws-tf-scp"
  }
}

# Configure and downloading plugins for aws default
provider "aws" {
  region = var.aws_region
}

# Target
provider "aws" {
  alias  = "target"
  region = var.aws_region
  assume_role {
    role_arn    = "arn:aws:iam::${var.account_id}:role/AWSAFTExecution"
    external_id = "ASSUME_ROLE_ON_TARGET_ACC"
  }
}
