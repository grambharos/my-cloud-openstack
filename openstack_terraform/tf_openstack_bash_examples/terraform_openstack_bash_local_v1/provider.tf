# Provider details

provider "openstack" {
  region      = "ams1"
  tenant_name = "dev-grambharos"
  auth_url    = "https://keystone.ams1.cloud.ecg.so/v2.0"
}

