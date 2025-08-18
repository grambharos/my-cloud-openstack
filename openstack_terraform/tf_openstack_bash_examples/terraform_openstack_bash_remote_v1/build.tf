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

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y install httpd",
      "sudo firewall-cmd --permanent --add-port=80/tcp",
      "sudo firewall-cmd --permanent --add-port=443/tcp",
      "sudo firewall-cmd --reload",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo systemctl status httpd",
    ]
  }
}
