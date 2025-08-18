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
      "sudo amazon-linux-extras install ansible2 -y",
      "sudo yum install git -y",
      "git clone https://github.com/devops-school/ansible-hello-world-role /tmp/ans_ws",
      "ansible-playbook /tmp/ans_ws/site.yaml"
    ]
  }

     //   provisioner "remote-exec" {
  //   command = ["ansible-playbook -u root --private-key ${var.key_pair} -i ${self.ipv4_address} create-user.yml -e 'email_id=${var.email_id}'"]
  // }

  //    provisioner "local-exec" {
  //     command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook  '${self.jenkins_master.public_ip},' master.yml"
  // }

}
