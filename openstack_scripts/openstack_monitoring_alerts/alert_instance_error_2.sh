#!/usr/bin/env bash

#this will check instance with status error
#dev instance will be reset to active
#nondev instance will stay as is

echo "Check instances which are in an error state"
instances_error=$(openstack server list -f value --all --status ERROR -c ID)
for i in $(echo $instances_error | tr " " "\n")
do
    echo "Check instance:" $i
    # openstack server show $i
    # instance_details=$(openstack server show $i -f json | grep -w 'created\|id\|status\|addresses' | head -n4 | tr '",' ' ')
    instance_details=$(openstack server show $i  -f json | grep -w 'created\|id\|status\|addresses\|OS-EXT-STS:vm_state' | head -n5 | tr '",' ' ')
    instance_vmstate=$(echo "$instance_details" | grep -w 'OS-EXT-STS:vm_state' | awk '{print $3}')
    instance_state=$(echo "$instance_details" | grep -w 'status' | awk '{print $3}')
    echo $instance_vmstate
    echo $instance_state
    instance_addresses=$(echo "$instance_details" | grep -w 'addresses' | awk '{print $3}')
    instance_created=$(echo "$instance_details" | grep -w 'created' | awk '{print $3}' | tr "T" "\n" )
    instance_created_date=$(echo $instance_created | awk '{print $1}')
    last_month=$(date -v-1m +%Y-%m-%d)
    contains_dev='dev'
    vm_state='running'
    #check if instance is from a dev project AND older then 1 month
    if [[ ($instance_addresses == *$contains_dev*) && ($instance_created_date < $last_month) ]]; then
        echo "instance is dev"
        echo "reset state"
        nova reset-state --active $i
    elif [[ ($instance_addresses != *$contains_dev*) && ($instance_vmstate == *$vm_state*) ]]; then
        echo "instance is not dev but runnning error"
        # nova reset-state --active $i
    else
        echo "instance is not dev but error error"
        # nova reset-state --active $i
    fi
done
