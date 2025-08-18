resource "openstack_blockstorage_volume_v2" "volume_1" {
  name = "volume_1"
  size = 1
}



resource "openstack_compute_instance_v2" "instance_" {
  name            = "instance_1"
  image_id        = "2d263724-857d-4bbb-89be-5980e8a02d7c"
  flavor_id       = "0010"
  key_pair        = "grambharos"
  security_groups = ["default"]

  network {
    name = "dev-grambharos-net"
  }

  block_device {
    uuid                  = "2d263724-857d-4bbb-89be-5980e8a02d7c"
    source_type           = "image"
    destination_type      = "local"
    boot_index            = 0
    delete_on_termination = true
  }

  block_device {
    uuid                  = "${openstack_blockstorage_volume_v2.volume_1.id}"
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 1
    delete_on_termination = true
  }
}