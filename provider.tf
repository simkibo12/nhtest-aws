terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.33.0"
    }
  }
   backend "s3" {
    bucket = "nh-terraform-bucket"
    key    = "global/s3/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

provider "aws"{
access_key  = "${var.access_key}"
secret_key  = "${var.secret_key}"
region = "ap-northeast-2"
}
