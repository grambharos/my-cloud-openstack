# Nomad cluster

This repository contains `terraform` and `ansible` code required to instantiate
and provision a fully operating Nomad cluster that uses Consul for
auto-clustering and service discovery.

The infrastructure created is as follows:

- 3 Nomad + Consul servers (Nomad and Consul servers on the same machines)
- 5 Nomad workers (Nomad clients + Consul clients + docker)

## Instantiating

```
cd terraform
terraform init
terraform plan
terraform apply
```

## Provisioning

```
cd ansible
ansible-playbook -i inventory site.yml -u cloud
```

## securtiy group rules

```
set-user grambharos
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 4646 --prefix 0.0.0.0 default
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 8500 --prefix 0.0.0.0 default
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 15672 --prefix 0.0.0.0 default
```

## run hcl

```
go to http://nomad-server-1.dev-grambharos.ams1.cloud:4646/ui/clients
run job and past the rabbitmq.hcl
```