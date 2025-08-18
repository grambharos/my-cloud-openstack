resource "openstack_compute_instance_v2" "basic" {
  name            = "basic"
  image_id        = "2d263724-857d-4bbb-89be-5980e8a02d7c"
  flavor_id       = "0010"
  key_pair        = "grambharos"
  security_groups = ["default"]

  metadata = {
    # Properties
    this = "thatgermio"
  }

  network {
    name = "dev-grambharos-net"
  }
}