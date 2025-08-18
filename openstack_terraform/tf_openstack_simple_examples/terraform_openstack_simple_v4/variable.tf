# variables instance

variable "image_id" {
    type    = string
    default = "2d263724-857d-4bbb-89be-5980e8a02d7c"
}

variable "flavor_id" {
    type    = string
    default = "0010"
}

variable "network_name" {
    type    = string
    default = "dev-grambharos-net"
}

variable "key_pair" {
    type    = string
    default = "grambharos"
}