provider "aws" {
  shared_credentials_file = "${var.aws_shared_credentials_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

module "config-external_module" {
  source          = "../../modules/module_template"
  resource_stuff  = "${var.common["example_variable"]}"
  different_stuff = "${var.config["module_specific_variable"]}"
}