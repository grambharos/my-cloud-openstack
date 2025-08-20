# Provider details

terraform {
  required_version = ">= 0.15.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.40"
    }
  }
}
provider "openstack" {
  region      = "ams1"
  tenant_name = "cloud-prod"
  auth_url    = "https://keystone.ams1.cloud.ecg.so/v2.0"
}
