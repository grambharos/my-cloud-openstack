

variable "keypair" {
    type    = string
    default = "grambharos"
}

variable "name" {
    type    = string
    default = "toolbox-4"
}

variable "zone" {
    type    = string
    default = "zone4"
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

variable "domain_name" {
    type    = string
    default = "cloud-prod.ams1.cloud"
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

variable "foreman_hostgroup" {
    type = string
    default = "toolbox"
}

variable "foreman_organisation" {
    type = string
    default = "CLOUD"
}

variable "foreman_server" {
    type = string
    default = "foreman.ams5.init1.cloud"
}