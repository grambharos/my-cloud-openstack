resource "openstack_blockstorage_volume_v2" "myvol" {
  name = "myvol"
  size = 1
}

resource "openstack_compute_instance_v2" "myinstance" {
  name            = "myinstance"
  image_id        = "2d263724-857d-4bbb-89be-5980e8a02d7c"
  flavor_id       = "0010"
  key_pair        = "grambharos"
  security_groups = ["default"]

  network {
    name = "dev-grambharos-net"
  }
}

resource "openstack_compute_volume_attach_v2" "attached" {
  instance_id = openstack_compute_instance_v2.myinstance.id
  volume_id   = openstack_blockstorage_volume_v2.myvol.id
}

