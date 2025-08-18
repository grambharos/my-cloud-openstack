output "public_ip" {
  value = "${openstack_compute_floatingip_associate_v2.node.*.floating_ip[0]}"
}

output "private_ip" {
  value = "${openstack_compute_floatingip_associate_v2.node.*.fixed_ip[0]}"
}

output "ssh_user_name" {
  value = "${var.ssh_user_name}"
}

output "ssh_private_key" {
  value = "${var.ssh_key_file}"
}
