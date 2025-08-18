#!/usr/bin/env bash

# check hosts with spare aggregate
check_spare=$(openstack aggregate show spare | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
if [[ -z $check_spare ]]; then
    echo "OK: No hosts with aggregate: spare"
    exit 0
else
    # check each host with spare aggregate
    result=$(
    for host in $check_spare; do
        openstack hypervisor show $host -f json | jq -rcj '.hypervisor_hostname, .status, .aggregates' | tr '\n' ' ' | tr '"[]' ' ';
        done)
    echo "RESULT:" "$result"
fi
