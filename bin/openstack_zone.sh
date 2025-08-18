#!/usr/bin/env bash

#####################################################################
# script openstack_rc - dns/zone                                     #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. $load_rc

#ZONE-DNS =========================================================================================================================================================================================#

# zone-list
function os-zone-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: zone-list 'projectid' %s\n"
  elif [ "$#" -eq 0 ]; then
    printf "list all projects zones.\n"
    # admin
    openstack zone list --all-projects
  else
    printf "list project zone.\n"
    #admin
    #openstack zone list --sudo-project-id $1
    openstack zone list
  fi
}

function os-zone-list-ecg-tools() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone-id' %s\n"
  else
    print "ecg.tools is only in ams1 zone_id project_id %s\n"
    openstack zone list | grep ecg.tools
  fi
}

# zone-show
function os-zone-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: zone-show 'zone-id' %s\n"
  else
    openstack zone show --all-projects $1
  fi
}

function os-zone-create() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'dns' 'email' \n"
  else
    openstack zone create --email "$2" "$1"
  fi
}

function os-zone-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'url' \n"
  else
    openstack zone delete "$1"
  fi
}
#DNS-RECORDS=========================================================================================================================================================================================#

function os-recordset-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone-id' %s\n"
  else
    #admin  # openstack recordset list --all-projects "$1"
    openstack recordset list "$1"
  fi
}

function os-recordset-show() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone-id' 'recordset-id' %s\n"
  else
    #admin openstack recordset show --all-projects zone_id id
    #admin openstack recordset show --all-projects "$1" "$2"
    openstack recordset show "$1" "$2"
  fi
}

function os-recordset-create() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone-id' 'new domain' %s\n"
  else
    # openstack recordset create <zone_id> <id>
    # openstack recordset create ek.ecg.tools. kibana.nonprod.ek.ecg.tools.
    openstack recordset create "$1" "$2"
  fi
}

function os-recordset-delete() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone-id' 'recordset-id' %s\n"
  else
    read "response?Are you sure you want to delete this recordset? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      # openstack recordset delete <zone_id> <recordset-id> --edit-managed --all-p
      # admin openstack recordset delete "$1" "$2" --edit-managed --all-p
      openstack recordset delete "$1" "$2" --edit-managed --all-p
      printf "$red recordset $1 has been deleted\n"
    else
      printf "$red recordset delete canceled\n"
    fi
  fi
}

# https://docs.openstack.org/python-openstackclient/latest/cli/plugin-commands/designate.html
# openstack dns service list

#ZONE-COMPUTE===========================================================================================================#
function os-zone-compute-list() {
  if [[ ("$#" -eq 0) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone'"
  else
    #hypervisors
    compute_result=$(openstack compute service list --sort Hypervisor --long | grep $1)
    compute_all=$(echo "$compute_result")
    compute_up=$(echo "$compute_result" | grep -w 'enabled')
    compute_down=$(echo "$compute_result" | grep -w 'disabled')
    #aantal
    compute_result_aantal=$(openstack compute service list --sort Hypervisor --long -f value | grep $1)
    compute_all_aantal=$(echo "$compute_result_aantal" | wc -l)
    compute_up_aantal=$(echo "$compute_result_aantal" | grep -w 'enabled' | wc -l)
    compute_down_aantal=$(echo "$compute_result_aantal" | grep -w 'disabled' | wc -l)
    printf $yellow"List computes\n"
    printf "$purple compute-all:\n"$purple$compute_all"\n"
    printf "$green compute-up:\n"$green$compute_up"\n"
    printf "$red compute-down:\n"$red$compute_down"\n"
    printf $yellow"Computes\n"
    printf "$purple compute-all\t:"$purple$compute_all_aantal"\n"
    printf "$green compute-up\t:"$green$compute_up_aantal"\n"
    printf "$red compute-down\t:"$red$compute_down_aantal"\n"
    # printf $white"hosts\t:\n"$host_all_aantal"\n"
  fi
}

#ZONE-HOSTS=============================================================================================================#
# host : wijst de hypervisors en nova services die (enabled)

function os-zone-host-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    #all zones
    zone_list=$(openstack host list --sort Zone)
    echo $zone_list
  else
    #one or multiple zones
    for zone in "$@"; do
      zone_list=$(openstack host list --sort Zone --zone $zone)
      zone_list_aantal=$(echo $zone_list | wc -l)
      printf $yellow"List hypervisors zone: $zone"
      printf $green$zone_list
      printf $green$zone_list_aantal
    done
  fi
}

function os-zone-host-instances-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: host-list-instances-zone 'zone' %s\n"
  else
    zone_hv=$(openstack host list -f value --sort Zone --zone $1 | awk '{print $1}')
    echo $zone_hv | while read -r line; do
      echo "List instances hypervisor $line"
      # openstack server list -f value --all-projects --host $line >> ~/openstack_all/instances_$zone_hv_$line.txt
      openstack server list -f csv --all-projects --host $line -c ID -c Name -c Flavor >>~/openstack_all/instances_$zone_hv_$line.txt
    done
  fi
}

function os-zone-host-instances-list-file() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: host-list-instances-list_rack 'file' %s\n"
    printf "$blue Usage: host-list-instances-list_rack 'dus2-r003' %s\n"
  else
    rack="$1"
    rack_dir="host_$1"
    rack_file="host_rack_$1.txt"
    #delete directory if exists
    if [ -d "$HOME/$rack_dir" ]; then
      rm -rf $HOME/$rack_dir
    fi
    #create directory
    mkdir -p $HOME/$rack_dir
    cat $rack_file | while read -r host; do
      printf $yellow"list instances on host $host\n"
      #get project id
      project_host=$(nova list --all-tenants --host $host | tr -d '|+' | awk '{print $3}' | tail -n +4 | tail -r | tail -n +2 | sort | uniq)
      #get instances
      echo "$project_host" | while read -r project_id; do
        echo "project_check: $project_id"
        project_name=$(openstack project list -f value | grep $project_id | awk '{print $2}')
        instances_host=$(openstack server list -f csv --long --project $project_id --host $host -c ID -c Name -c Networks -c "Flavor Name" -c "Availability Zone" -c Host | tail -n +2)
        if [[ $(echo "$instances_host" | wc -l) -eq 1 ]]; then
          printf '%-5s %-5s %-5s %-5s \n' "$rack,""$project_name,""$project_id,""$instances_host" >>$HOME/$rack_dir/"instances_$host.txt"
        else
          echo "$instances_host" | while read -r instances_host_line; do
            printf '%-5s %-5s %-5s %-5s \n' "$rack,""$project_name,""$project_id,""$instances_host_line" >>$HOME/$rack_dir/"instances_$host.txt"
          done
        fi
      done
    done
    cd $HOME/$rack_dir
    printf "$green files merged"
    cat *.txt | sort >merged_$rack.csv
    cd $HOME
  fi
}

# function zone-host-instances-list-test() {
# # set -x
#   host="compute-30nb.dus1.cloud.ecg.so"
#   echo "host: $host"
#   #get instances host
#   # check_hv1=$(nova list --all-tenants --host $host)
#   # check_hv2=$(openstack server list -f value --all-projects --host $host)
#   project_host=$(nova list --all-tenants --host $host | tr -d '|+' | awk '{print $3}' | tail -n +4  | tail -r | tail -n +2 | sort | uniq)
#   echo $project_host > $host.txt
#   echo "$project_host" | while read -r project_id;
#   do
#     echo "project_check: $project_id"
#     instances_host=$(openstack server list -f value --long --project $project_id --host $host -c ID -c Name -c Networks -c "Flavor Name" -c "Availability Zone" -c Host)
#     printf '%-10s\n' "$instances_host" >> $HOME/openstack_file/"instances_$host.txt"
#   done;
# }

# function zone-host-instances-list_file_tenant() {
#   if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#     printf "$blue Usage: host-list-instances-list_file 'file' %s\n"
#     printf "$blue Usage: host-list-instances-list_file 'hv_rack_dus2-r003.txt' %s\n"
#   else
#     # zone_hv=$(openstack host list -f value --sort Zone --zone $1 | awk '{print $1}')
#     cat $1 | while read -r line; do
#       echo "List instances hypervisor $line"
#       nova list --all-tenants --host $line
#       openstack server list -f csv --all-projects --host $line  -c ID -c Name -c Flavor |  >> ~/openstack_file/instances_$zone_hv_$line.txt
#     done
#   fi
# }

# function zone-host-instances-list-AMD() {
#   if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#     printf "$blue Usage: host-list-instances-zone'zone' %s\n"
#   else
#     zone_hv=$(openstack host list -f value --sort Zone --zone $1 | awk '{print $1}' | grep dus2-control.underlay.cloud)
#     echo $zone_hv | while read -r line; do
#       echo "List instances hypervisor $line"
#       openstack server list -f value --all-projects --host $line >> ~/openstack/instances_AMD_$zone_hv_$line.txt
#     done
#   fi
# }

# function zone-host-instances-list-AMD-flavor() {
#   if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#     printf "$blue Usage: host-list-instances-zone 'zone' %s\n"
#   else
#     zone_hv=$(openstack host list -f value --sort Zone --zone $1 | awk '{print $1}' | grep dus2-control.underlay.cloud)
#     echo $zone_hv | while read -r line; do
#       echo "List instances hypervisor $line"
#       openstack server list -f csv --all-projects --host $line  -c ID -c Name -c Flavor |  >> ~/openstack/AMD_instances_$zone_hv_$line.txt
#     done
#   fi
# }

# complete -W "zone1 zone2 zone3 zone4 shared dedicated testing spare" zone-host-aggregate-list
function os-zone-host-aggregate-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'zone' \n"
  else
    zone_aggregate_list=$(openstack aggregate show $1 -f json | jq '.hosts' | tr '",[]' ' ')
    zone_list_aantal=$(echo $zone_aggregate_list | wc -l)
    printf $yellow"List zone: "$1"\n"
    echo $green$zone_aggregate_list
    printf "$purple host amount:"$zone_list_aantal"\n"
  fi
}

# function zone-host-aggregate-list-AMD(){
#   if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#     printf "$blue Usage: zone-host-aggregate-list 'zone' \n"
#   else
#     zone_aggregate_list=$(openstack aggregate show $1 -f json | jq '.hosts' | tr '",[]' ' '| grep dus2-control.underlay.cloud)
#     zone_list_aantal=$(echo $zone_aggregate_list | wc -l)
#     printf $yellow"List zone: "$1"\n"
#     echo $green$zone_aggregate_list
#     printf "$purple host amount:"$zone_list_aantal"\n"
#   fi
# }

# dns-set
# $openstack zone set --description "Description" example.com.

# dns-create
# $openstack zone create --email admin@example.com example.com.

# dns-delete
# $openstack zone delete example.com.
