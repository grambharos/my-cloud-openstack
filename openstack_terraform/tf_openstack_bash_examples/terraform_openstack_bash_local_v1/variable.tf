# instance details

variable "name" {
    type    = string
    default = "tf-instance-script"
}

variable "image_id" {
    type    = string
    default = "78b06595-9172-410a-a88a-29ec161a7863"
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
