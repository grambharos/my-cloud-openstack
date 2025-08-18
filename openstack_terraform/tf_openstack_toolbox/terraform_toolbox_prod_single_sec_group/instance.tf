# Instance creation

resource "openstack_compute_instance_v2" "toolbox" {
  name              = var.name
  image_name        = var.image_name
  flavor_name       = var.flavor_name
  key_pair          = var.keypair
  availability_zone = var.zone
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  network {
    name = var.network_name
  }
  # default scheduling rules
  scheduler_hints {
    group = openstack_compute_servergroup_v2.sg.id
  }

}
  #create a ssh_config from template
  resource "local_file" "ssh_config_file" {
      content = templatefile("${path.module}/templates/ssh_config.tpl", {
        node_ip = openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4
        node_user = var.keypair
        })
      filename = "ssh_custom.cfg"
  }

  #create a puppet_config from template
  resource "local_file" "puppet_config_file" {
      content = templatefile("${path.module}/templates/puppet_config.tpl", {
        organisation  = var.foreman_organisation
        environment   = var.puppet_environment
        server        = var.puppet_server
        ca_server     = var.puppet_ca_server
        })
      filename = "${path.module}/ansible/puppet/files/puppet.conf"
  }

  #create a update_host script from template
  resource "local_file" "foreman_script_file" {
      content = templatefile("${path.module}/templates/foreman_update.tpl", {
        node_name       = format("%s.%s", var.name, var.domain_name)
        foreman         = var.foreman_server
        hostgroup       = var.foreman_hostgroup
        environment     = var.puppet_environment
        server          = var.puppet_server
        ca_server       = var.puppet_ca_server
        })
      filename = "${path.module}/scripts/update_host.sh"
  }

  # anti-affinity rule
  resource "openstack_compute_servergroup_v2" "sg" {
    name     = "toolbox"
    policies = ["anti-affinity"]
  }

  # security rules
  resource "openstack_networking_secgroup_v2" "secgroup" {
    name        = "toolbox_secgroup"
    description = "Toolbox security group"
  }
  # allow ping
  resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_icmp" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "icmp"
    port_range_min    = "0"
    port_range_max    = "0"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.secgroup.id
  }
  # allow 22
  resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ssh" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 22
    port_range_max    = 22
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.secgroup.id
  }
  # run ansible playbooks
  resource "null_resource" "scripts" {
    #run ldap playbook
    provisioner "local-exec" {
      command = "sleep 120; ansible-playbook -u cloud -i ${openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4}, ansible/ldap/deploy_ldap.yaml"
    }
    #run jira playbook
    provisioner "local-exec" {
      command = "ansible-playbook -u cloud -i ${openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4}, ansible/jira/deploy_jiraldap.yaml"
    }
    #run puppet playbook
    provisioner "local-exec" {
      command = "ansible-playbook -u cloud -i ${openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4}, ansible/puppet/deploy_puppet.yaml"
    }
    # foreman update host
    provisioner "local-exec" {
      command = "sleep 60; bash ./scripts/update_host.sh"
    }
}