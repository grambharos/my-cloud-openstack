resource "openstack_compute_keypair_v2" "terraform" {
  name = "terraform-puppet"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

module "puppet-master" {
  source = "../../"

  name = "puppet-master"
  key_pair = "${openstack_compute_keypair_v2.terraform.name}"
  network_uuid = "${var.network_uuid}"
  flavor = "m1.medium"
  pool = "${var.pool}"
  ssh_key_file = "${var.ssh_key_file}"
  node_type = "puppet-master"
  pe_source_url = "${var.pe_source_url}"
  pe_conf = <<EOF
{
  "console_admin_password": "puppetlabs"
  "puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
  "pe_install::puppet_master_dnsaltnames": ["puppet-master"]
}
EOF
  custom_provisioner = [
    "echo puppetlabs | sudo /opt/puppetlabs/bin/puppet-access login --lifetime=0 --username admin",
  ]
}

module "puppet-agent" {
  source = "../../"

  name = "puppet-agent"
  key_pair = "${openstack_compute_keypair_v2.terraform.name}"
  network_uuid = "${var.network_uuid}"
  flavor = "g1.medium"
  pool = "${var.pool}"
  ssh_key_file = "${var.ssh_key_file}"
  node_type = "posix-agent"
  master_ip = "${module.puppet-master.private_ip}"
  master_hostname = "puppet-master"
}
