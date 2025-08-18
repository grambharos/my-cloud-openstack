resource "openstack_compute_instance_v2" "basic_script" {
  name            = "basic_script"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  user_data       = file("first-boot.sh")
  security_groups = ["default"]

  metadata = {
    this = "thatgermio"
  }

  network {
    name = "dev-grambharos-net"
  }
}