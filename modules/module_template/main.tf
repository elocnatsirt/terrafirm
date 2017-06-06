resource "provider" "resource" {
  resource_stuff      = "${var.resource_stuff}"
  more_resource_stuff = "${var.different_stuff}"
}

resource "provider" "another_resource" {
  even_more_stuff = "${provider.resource.name}"
}