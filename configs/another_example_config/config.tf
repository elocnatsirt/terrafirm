module "example_module" {
  source          = "../../modules/example_module"
  resource_stuff  = "${var.common["example_variable"]}"
  different_stuff = "${var.config["module_specific_variable"]}"
}