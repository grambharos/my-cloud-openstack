variable "pe_source_url" {
  description = "The URL to source the Puppet Enterprise installer from."
}

variable "network_uuid" {
  description = "The UUID of the network to place the nodes in."
}

variable "pool" {
  description = "The pool to assign a floating IP from."
}

variable "ssh_key_file" {
  description = "The location of the SSH private key to use."
  default     = "~/.ssh/id_rsa.terraform"
}
