# toolbox deployment

## What it does

- This creates a toolbox instance
- connects using ssh and deploys ansible playbooks

## Prerequisites

1.Install gcloud (MacOS)

```
$ brew install --cask google-cloud-sdk
```

2.Permissions

```
Ask for permissions to the ecg-cloud-prod GCP project in #cloud-sre
or #cloud-team.
Check that it works at https://console.cloud.google.com/
```

3.Source the following via your .bashrc/.zshrc file:

```
$ source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
$ source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
```

Configure auth (use `$USER_NAME@ebay.com` account):

```
$ gcloud auth application-default login
$ gcloud auth application-default set-quota-project ecg-cloud-prod

```

## Deployment

1. source your openstack credentials for the region you want to deploy (set environment)

2. make changes to variables.tf

3. please revoke the existing cert in foreman if this is a rebuild (smart proxies)

```
terraform init
terraform plan -var keypair=<your_key_name> -out=toolbox-tfplan
terraform apply "toolbox-tfplan"
OR
terraform init && terraform plan
terraform init && terraform plan && terraform apply -auto-approve
```

## Destroying

1.destroy a specific instance in the current region and project (safer)

```
terraform destroy -var keypair=<your_key_name> -target="module.toolbox.openstack_compute_instance_v2.toolbox-[0]"
```

2.destroy all instances in the current region and project

```
terraform destroy -var keypair=<your_key_name>
OR
terraform destroy -auto-approve
```
