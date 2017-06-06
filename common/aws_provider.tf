# NOTE: This file is symlinked to configurations!
# Changing this will affect everything using an S3 remote state

variable "aws" {
  type    = "map"
  default = {
    region           = "us-east-1"
    aws_profile_name = "default"
  }
}

provider "aws" {
  region  = "${var.aws["region"]}"
  profile = "${var.aws["aws_profile_name"]}"
}

terraform {
  backend "s3" {}
}