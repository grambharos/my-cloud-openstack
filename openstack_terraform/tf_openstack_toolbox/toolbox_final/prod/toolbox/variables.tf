

variable "keypair" {
    type    = string
    default = "grambharos"
}

variable "instance_nr" {
    type = number
    default = 4
}

variable "image_name" {
    type    = string
    default = "ecg-centos-7"
}

variable "flavor_name" {
    type    = string
    default = "1C-1G-10G-V1-S"
}

variable "network_name" {
    type    = string
    default = "cloud-prod"
}

variable "security_groups" {
    type = list
    default = ["default"]
}

variable "puppet_server" {
    type = string
    default = "foreman-proxy-1.cloud-prod.ams1.cloud"
}

variable "puppet_ca_server" {
    type = string
    default = "foreman-proxy-1.cloud-prod.ams1.cloud"
}

variable "puppet_environment" {
    type = string
    default = "ams1_overlay"
}

variable "fqdn" {
    type    = string
    default = "cloud-prod.ams1.cloud"
}

