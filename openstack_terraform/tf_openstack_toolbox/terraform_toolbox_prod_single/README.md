# toolbox deployment

## what it does

- This creates a toolbox instance
- it creates a custom ssh_config
- connects using ssh and depluys ansible playbooks

## changes steps

- set environment
- make changes to variable.tf
- please revoke the existing cert in foreman if this is a rebuild (smart proxies)

## build steps

- terraform init && terraform plan
- terraform init && terraform plan && terraform apply -auto-approve

## destroy steps

- terraform destroy -auto-approve
