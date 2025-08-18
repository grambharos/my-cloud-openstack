/*
Objective:
Create a instance in openstack, with existing image, flavor, keypair, security-group and network resources.

Using output block to display the output of ID, name and fixed IP parameters.

*/


# Provider details 

provider "openstack" {
  user_name   = "demo"
  tenant_name = "demo"
  password    = "openstack123"
  auth_url    = "http://10.0.1.6/identity"
  region      = "RegionOne"
  domain_name = "default"
}

# Instance creation 

resource "openstack_compute_instance_v2" "vm1" {
  name            = "vm1"
  image_id        = "dea87f06-9fdc-410c-974f-470b057cfa2b"
  flavor_id       = "1"
  key_pair        = "mykey"
  security_groups = ["default"]
  network {
    uuid = "db4a268a-465d-40d7-9db2-54b82d945bec"
  }
}

# output vm name variable 

output "vm-name" {
  value = "${openstack_compute_instance_v2.vm1.name}"
}

# output vm-id variable 

output "vm-id" {
  value = "${openstack_compute_instance_v2.vm1.id}"
}

# output vm-ip variable 

output "vm-ip" {
	value = "${openstack_compute_instance_v2.vm1.network.0.fixed_ip_v4}"
}

