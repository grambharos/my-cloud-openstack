variable "auth_url" {}
variable "project_domain_name" {}
variable "user_domain_name" {}
variable "region" {}
variable "tenant_name" {}
variable "tenant_id" {}
variable "user_name" {}
variable "unique_network_name" {}
variable "password" {}
variable "ssh_key_public" {}
variable "ssh_key_private" {}

provider "openstack" {
    auth_url            = "${var.auth_url}"
    project_domain_name = "${var.project_domain_name}"
    user_domain_name    = "${var.user_domain_name}"
    region              = "${var.region}"
    tenant_name         = "${var.tenant_name}"
    tenant_id           = "${var.tenant_id}"
    user_name           = "${var.user_name}"
    password            = "${var.password}"
}

output "terraform-provider" {
    value   = "connected with openstack at ${var.auth_url}"
}