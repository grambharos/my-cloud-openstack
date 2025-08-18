# Instance creation

resource "openstack_compute_instance_v2" "vm1_instance" {
  name            = var.name
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  user_data       = file("script/first-boot.sh")
  security_groups = ["default"]
  network {
    name = var.network_name
  }
}
