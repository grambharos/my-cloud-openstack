# Steps

## cd $HOME/git/cloud/ansible/maintenance-playbooks/migrate-single-instance

## hosts file

- localhost: add source hostname
- controllers: depending on which region
  - ix3: allinone-controller-0hdu.ix3-control.cloud.ecg.so
  - dus2: allinone-controller-2z0k.dus2-control.cloud.ecg.so

## run playbook

- Use: ansible-playbook -vvv migrate-instance.yaml --extra-vars "ansible_user=<user_> exec_all=true dst_all=true uuid=<instance_id> destination=<compute_>"
- Use: ansible-playbook -vvv migrate-instance.yaml --extra-vars "ansible_user=grambharos exec_all=true dst_all=true uuid=9ed41a13-90cf-48a9-9cf5-2fdbfa317da5 destination=compute-control-08i6.ams3-control.underlay.cloud"
