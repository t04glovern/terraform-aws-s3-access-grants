terraform {
  # backend "s3" {
  #   bucket         = "tf-state-bucket-222222222222-ap-southeast-2"
  #   key            = "terraform-aws-s3-access-grants/terraform.tfstate"
  #   region         = "ap-southeast-2"
  #   dynamodb_table = "tf-state-table-222222222222"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.59.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
