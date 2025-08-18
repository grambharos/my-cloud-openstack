# Instance creation

resource "openstack_compute_instance_v2" "vm1_instance" {
  name            = var.name
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  security_groups = ["default"]
  network {
    name = var.network_name
  }
  // connection {
  //   type = "ssh"
  //   user = "cloud"
  //   host = openstack_compute_instance_v2.vm1_instance.network.0.fixed_ip_v4
  // }
  provisioner "local-exec" {
    command = "sleep 120; ansible-playbook -u cloud -i ${openstack_compute_instance_v2.vm1_instance.network.0.fixed_ip_v4}, ansible/nginx_playbook.yaml"
  }
}
