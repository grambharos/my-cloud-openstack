variable "network_uuid" {
  description = "The UUID of the network to place the nodes in."
}

variable "pool" {
  description = "The pool to assign a floating IP from."
}

variable "master_ip" {
  description = "The IP of Puppet master."
}

variable "windows_admin_password" {
  description = "The password to use for the Administrator user."
}
