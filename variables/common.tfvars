# This is a common variable file for defaults across all modules
# Set defaults here and override per environment if necessary

# AWS Variables
variable "aws_shared_credentials_file" {
  type    = "string"
  default = "../../../.aws/credentials"
}
variable "aws_profile" {
  type    = "string"
  default = "default"
}
variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "common" {
  type    = "map"
  default = {
    example_variable = "common_example"
  }
}

variable "internal_module" {
  type    = "map"
  default = {
    module_specific_variable = "common_example"
  }
}