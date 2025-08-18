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

  # connect details
  connection {
    host = openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4
    type = "ssh"
    user = "cloud"
  }
    # install openldap clients
    provisioner "remote-exec" {
      inline = [
        "sleep 60",
        "sudo yum -y install openldap-clients",
      ]
    }
    #copy file to tmp
    provisioner "file" {
      source = "scripts/ldap.conf"
      destination = "/tmp/ldap.conf"
    }

    #replace file
    provisioner "remote-exec" {
      inline = [
        "sudo cp -f /tmp/ldap.conf /etc/openldap/",
      ]
    }

    #run playbook
    provisioner "local-exec" {
      command = "sleep 60; ansible-playbook -u cloud -i ${openstack_compute_instance_v2.toolbox.network.0.fixed_ip_v4}, ansible/deploy.yaml"
    }

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
  resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "icmp"
    port_range_min    = "0"
    port_range_max    = "0"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.secgroup.id
  }
  # allow 22
  resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 22
    port_range_max    = 22
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.secgroup.id
  }
