# Instance creation

resource "openstack_compute_instance_v2" "toolbox" {
  name            = "toolbox-${count.index + 1}"
  availability_zone = format("zone%d", (count.index % 4) + 1)
  count             = var.instance_nr
  image_name        = var.image_name
  flavor_name       = var.flavor_name
  key_pair          = var.keypair
  security_groups   = var.security_groups
  user_data         = templatefile("${path.module}/templates/user-data.yaml", {
                        puppet_server = var.puppet_server,
                        puppet_ca_server = var.puppet_ca_server,
                        puppet_environment = var.puppet_environment
                      })
  network {
    name = var.network_name
  }
  # default scheduling rules
  scheduler_hints {
    group = openstack_compute_servergroup_v2.sg.id
  }

}
  # anti-affinity rule
  resource "openstack_compute_servergroup_v2" "sg" {
    name     = "toolbox"
    policies = ["anti-affinity"]
  }

  # run ansible playbooks
  resource "null_resource" "ansible" {
    count = var.instance_nr
    provisioner "local-exec" {
      command = "sleep 240; ansible-playbook -i ${openstack_compute_instance_v2.toolbox[count.index].name}.${var.fqdn}, ../modules/toolbox/ansible/ldap/deploy_ldap.yaml"
    }
    provisioner "local-exec" {
      command = "ansible-playbook -i ${openstack_compute_instance_v2.toolbox[count.index].name}.${var.fqdn}, ../modules/toolbox/ansible/jira/deploy_jiraldap.yaml"
    }
}
