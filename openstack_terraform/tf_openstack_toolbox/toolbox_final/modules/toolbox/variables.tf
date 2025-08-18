
variable "keypair" {
    type    = string
}

variable "instance_nr" {
    type = number
}

variable "image_name" {
    type    = string
}

variable "flavor_name" {
    type    = string
}

variable "network_name" {
    type    = string
}

variable "security_groups" {
    type = list
    default = ["default"]
}

variable "puppet_server" {
    type = string
}

variable "puppet_ca_server" {
    type = string
}

variable "puppet_environment" {
    type = string
}

variable "fqdn" {
    type    = string
    default = "cloud-prod.ams1.cloud"
}
