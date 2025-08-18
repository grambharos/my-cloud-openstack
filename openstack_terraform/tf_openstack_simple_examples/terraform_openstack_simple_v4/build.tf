# Instance creation

resource "openstack_compute_instance_v2" "vm1" {
  name            = "vm1"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  security_groups = ["default"]
  network {
    name = var.network_name
  }
}
