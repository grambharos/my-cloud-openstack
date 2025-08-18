variable "name" {
  description = "The name of the instance in OpenStack."
  default     = "puppet-master"
}

variable "hostname" {
  description = "The hostname of the instance - defaults to the name."
  default     = ""
}

variable "domain" {
  description = "The domain name of the instance."
  default     = "openstack.vm"
}

variable "key_pair" {
  description = "The name of the SSH key pair used in OpenStack."
  default     = "terraform"
}

variable "image" {
  description = "The OpenStack image to use."
  default     = "centos_7_x86_64"
}

variable "flavor" {
  description = "The OpenStack flavour to use."
  default     = "m1.medium"
}

variable "volume_size" {
  description = "The size of the volume to create for the instance."
  default     = 1
}

variable "network_uuid" {
  description = "The network UUID to place the instance in."
}

variable "security_groups" {
  description = "An array of security groups to assign to the instance."
  type        = "list"
  default     = [ "default" ]
}

variable "floating_ip" {
  description = "Set to false to disable public IP allocation."
  default     = true
}

variable "pool" {
  description = "The floating IP pool to allocate from."
  default     = "public"
}

variable "ssh_user_name" {
  description = "The username of the SSH user - set to the default user for the image used."
  default     = "centos"
}

variable "ssh_key_file" {
  description = "The location of the SSH private key to use."
  default     = "~/.ssh/id_rsa.terraform"
}

variable "pp_role" {
  description = "The value of the pp_role trusted CSR extension, if any."
  default     = ""
}

variable "node_type" {
  description = "The type of node being created - one of 'puppet-master', 'puppet-compile', 'posix-agent' or 'windows-agent'"
  default     = "puppet-master"
}

variable "pe_source_url" {
  description = "Location of the Puppet Enterprise installer"
  default     = "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest"
}

variable "pe_conf" {
  description = "The content of pe.conf"
  default     = <<EOF
{
  "console_admin_password": "puppetlabs"
  "puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
  "pe_install::puppet_master_dnsaltnames": ["puppet-master.openstack.vm"]

  "puppet_enterprise::profile::master::check_for_updates": false
  "puppet_enterprise::send_analytics_data": false
}
EOF
}

variable "custom_provisioner" {
  description = "An array of provisioner commands to run in 'inline' style"
  default     = []
}

variable "master_ip" {
  description = "The IP of the Puppet master for agents to connect to."
  default     = ""
}

variable "master_hostname" {
  description = "The hostname of the Puppet master for agents to connect to."
  default     = "puppet-master"
}

variable "master_domain" {
  description = "The domain of the Puppet master for agents to connect to. Defaults to domain"
  default     = ""
}

variable "dns_alt_names" {
  description = "Set this when creating compile masters."
  default     = "puppet-master.openstack.vm"
}

variable "windows_admin_password" {
  description = "The password for the Windows 'Administrator' user"
  default     = "PuppetLabs1"
}
