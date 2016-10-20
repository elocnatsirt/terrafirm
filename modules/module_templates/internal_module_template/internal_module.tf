provider "aws" {
  shared_credentials_file = "${var.aws_shared_credentials_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

module "internal_module-external_module" {
  source          = "../../module_templates/external_module_template"
  resource_stuff  = "${var.common["example_variable"]}"
  different_stuff = "${var.internal_module["module_specific_variable"]}"
}