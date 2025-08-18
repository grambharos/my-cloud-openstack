resource "openstack_compute_instance_v2" "nomad-server" {
  count             = 3
  name              = "nomad-server-${count.index + 1}"
  image_name        = var.image_name
  flavor_name       = var.flavor_name
  key_pair          = var.key_pair
  availability_zone = var.zone
  security_groups   = var.security_groups

  # default scheduling rules
  scheduler_hints {
    group = openstack_compute_servergroup_v2.sg.id
  }
}

  # anti-affinity rule
  resource "openstack_compute_servergroup_v2" "sg" {
    name     = "nomad-server-group"
    policies = ["anti-affinity"]
  }
