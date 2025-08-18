output "instance-name" {
  value = "${openstack_compute_instance_v2.toolbox.name}"
}

// output "instance-hostname" {
//   value = "${openstack_compute_instance_v2.toolbox.name}.cloud-prod.ams1.cloud"
// }

output "instance-id" {
  value = "${openstack_compute_instance_v2.toolbox.id}"
}

output "instance-ip" {
	value = "${openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4}"
}