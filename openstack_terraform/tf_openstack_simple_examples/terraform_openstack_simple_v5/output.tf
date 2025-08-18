output "vm-name" {
  value = "${openstack_compute_instance_v2.vm1_instance.name}"
}

output "vm-id" {
  value = "${openstack_compute_instance_v2.vm1_instance.id}"
}

output "vm-ip" {
	value = "${openstack_compute_instance_v2.vm1_instance.network.0.fixed_ip_v4}"
}