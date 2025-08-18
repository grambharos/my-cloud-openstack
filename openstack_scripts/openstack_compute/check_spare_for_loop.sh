#!/usr/bin/env bash

# check hosts with spare aggregate
check_spare=$(openstack aggregate show spare | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
if [[ -z $check_spare ]]; then
    echo "OK: No hosts with aggregate: spare"
else
    # check each host with spare aggregate
    echo "$check_spare" | while read -r host;
    do
        host_aggregates=$(openstack hypervisor show $host -f json | jq -rcj '.status, .aggregates' | tr '\n' ' ' | tr '"[]' ' ')
        # spare and nova service disabled
        if [[ $host_aggregates == *"disabled"* && $host_aggregates == *"spare"* ]]; then
            echo "OK:" $host $host_aggregates
        else
            echo "NOT OK:" $host $host_aggregates
            exit 2
        fi
    done
fi
