#!/usr/bin/env bash

# Provide usage
usage() {
echo "Usage: $0 VM_ID"
exit 1
}

[[ $# -eq 0 ]] && usage

# Migrate the VM to an alternate hypervisor
echo -n "Migrating instance to alternate host"
VM_ID=$1
openstack server migrate $VM_ID --block-migration
VM_OUTPUT=$(openstack server show $VM_ID)
VM_STATUS=$(echo "$VM_OUTPUT" | grep status | awk '{print $4}')
while [[ "$VM_STATUS" != "VERIFY_RESIZE" ]]; do
echo -n "."
sleep 2
VM_OUTPUT=$(openstack server show $VM_ID)
VM_STATUS=$(echo "$VM_OUTPUT" | grep status | awk '{print $4}')
done
nova resize-confirm $VM_ID
echo " instance migrated and resized."
echo;

# Show the details for the VM
echo "Updated instance details:"
openstack server show $VM_ID

# Pause to allow users to examine VM details
read -p "Pausing, press <enter> to exit."