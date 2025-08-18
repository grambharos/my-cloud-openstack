# Node properties
locals {
  hostname = "${var.hostname == "" ? var.name : var.hostname}"
  fqdn     = "${local.hostname}.${var.domain}"
}

# SSH/WinRM connection details
locals {
  connection_type = "${local.os_type == "windows" ? "winrm" : "ssh"}"
  host            = "${openstack_compute_floatingip_v2.node.address}"
  user            = "${local.os_type == "windows" ? "Administrator" : var.ssh_user_name}"
  password        = "${local.os_type == "windows" ? var.windows_admin_password : "" }"
  private_key     = "${file(var.ssh_key_file)}"
}

data "openstack_images_image_v2" "node" {
  name        = "${var.image}"
  most_recent = true
}

resource "openstack_compute_floatingip_v2" "node" {
  count = "${var.floating_ip}"
  pool  = "${var.pool}"
}

resource "openstack_compute_instance_v2" "node" {
  name            = "${var.name}"
  image_name      = "${var.image}"
  flavor_name     = "${var.flavor}"
  key_pair        = "${var.key_pair}"
  security_groups = "${var.security_groups}"
  user_data       = "${local.user_data}"

  block_device {
    uuid                  = "${data.openstack_images_image_v2.node.id}"
    source_type           = "image"
    volume_size           = "${var.volume_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = "${var.network_uuid}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "node" {
  count       = "${var.floating_ip}"
  floating_ip = "${openstack_compute_floatingip_v2.node.address}"
  instance_id = "${openstack_compute_instance_v2.node.id}"
  fixed_ip    = "${openstack_compute_instance_v2.node.access_ip_v4}"

  provisioner "remote-exec" {
    connection {
      type        = "${local.connection_type}"
      host        = "${local.host}"
      user        = "${local.user}"
      password    = "${local.password}"
      private_key = "${local.private_key}"
    }

    inline = "${local.all_provisioners}"
  }
}
