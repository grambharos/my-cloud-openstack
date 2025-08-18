resource "openstack_compute_instance_v2" "basic_variable" {
  name            = "basic_variable"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  security_groups = ["default"]

  metadata = {
    this = "thatgermio"
  }

  network {
    name = "dev-grambharos-net"
  }
}