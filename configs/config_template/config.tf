module "config-external_module" {
  source          = "../../modules/module_template"
  resource_stuff  = "${var.common["example_variable"]}"
  different_stuff = "${var.config["module_specific_variable"]}"
}