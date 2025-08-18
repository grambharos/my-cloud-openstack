# instance details

variable "name" {
    type    = string
    default = "toolbox-3"
}

variable "zone" {
    type    = string
    default = "zone3"
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

variable "keypair" {
    type    = string
    default = "grambharos"
}
