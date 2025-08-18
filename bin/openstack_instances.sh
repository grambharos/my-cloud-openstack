#!/usr/bin/env bash

#####################################################################
# script openstackrc - instances                                    #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#INSTANCES=============================================================================================================#

function os-instance-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'project-id' or 'project-name' %s\n"
  elif [ "$#" -eq 0 ]; then
    echo "$purple Instances:\n"
    #listing
    server_list_all=$(openstack server list --long)
    server_list_up=$(echo "$server_list_all" | grep -i 'ACTIVE')
    server_list_down=$(echo "$server_list_all" | grep -vi 'ACTIVE')
    #count
    server_list_count=$(openstack server list -f value --long)
    server_list_count_all=$(echo "$server_list_count" | wc -l | tail -n +2)
    server_list_count_up=$(echo "$server_list_count" | grep -i 'ACTIVE' | wc -l | tail -n +2)
    server_list_count_down=$(echo "$server_list_count" | grep -vi 'ACTIVE' | wc -l | tail -n +2)
    #show
    echo "$green Instances up\n"$server_list_up "\n"
    echo "$red Instances down\n"$server_list_down"\n"
    echo "$yellow Amount instances total\t: "$server_list_count_all"\n"
    echo "$green Amount instances up\t: "$server_list_count_up
    echo "$red Amount instances down\t: "$server_list_count_down"\n"
  else
    for project in "$@"; do
      echo "$purple List instances: $project \n"
      #listing
      server_list_all=$(openstack server list --long --project $project -f value | tr ' ' '\t')
      server_list_up=$(echo "$server_list_all" | grep -i 'ACTIVE')
      server_list_down=$(echo "$server_list_all" | grep -vi 'ACTIVE')
      #count
      server_list_count=$(openstack server list -f value --long --project $project)
      server_list_count_all=$(echo "$server_list_count" | wc -l)
      server_list_count_up=$(echo $server_list_count | grep -i 'ACTIVE' | wc -l)
      server_list_count_down=$(echo $server_list_count | grep -vi 'ACTIVE' | wc -l)
      #show
      echo "$green Instances up\n"$server_list_up "\n"
      echo "$red Instances down\n"$server_list_down"\n"
      echo $yellow"Instances total\t: "$server_list_count_all
      echo "$green Instances up\t: "$server_list_count_up
      echo "$red Instances down\t: "$server_list_count_down"\n"
    done
  fi
}

function os-instance-network-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'network_name'.\n"
  else
    echo $yellow"Check network from instance:" "$1"
    instance_network=$(openstack server list --name "$1" -c Name -c Networks -f value)
    echo "$green Instance: "$instance_network
    network_name=$(echo $instance_network | awk '{print $2}' | awk -F '=' '{print "$1"}')
    # echo "Network name: "$network_name
    check_network=$(openstack network list --name $network_name)
    echo "$green Network info:\n"$check_network
    check_subnet=$(openstack subnet list --name $network_name)
    echo "$green Subnet info:\n"$check_subnet
  fi
}

function os-instance-network-ip-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'ip'.\n"
  else
    echo $yellow"Check IP" "$1"
    #check if fixed ip
    check_ip_fixed=$(openstack port list --fixed-ip ip-address="$1" -f value -c 'Fixed IP Addresses' | grep -w 'ip_address' | tr "'[{}],:" " ")
    if [[ ! -z $check_ip_fixed ]]; then
      echo "$green This is a Fixed IP"
      check_subnet_id=$(echo "$check_ip_fixed" | awk '{print $2}')
      check_project_id=$(openstack subnet show $check_subnet_id -f json | grep project_id | tr '":' ' ' | awk '{print $2}')
      project_show=$(openstack project list -f value | grep -i $check_project_id)
      instance_show=$(openstack server list --ip "$1" -c ID -c Name -c Status -c Networks -f value)
      echo "$green Project\t:" $project_show
      echo "$green Instance:" $instance_show
      echo "$green Network\t:" $check_ip_fixed
    else
      #check if floating ip
      check_ip_float=$(openstack floating ip list --floating-ip-address "$1" -f value)
      if [[ ! -z $check_ip_float ]]; then
        echo "$green This is a Float IP\n"
        check_project_id=$(echo "$check_ip_float" | awk '{print $6}')
        project_show=$(openstack project list -f value | grep -i $check_project_id)
        instance_show=$(openstack server list -c ID -c Name -c Status -c Networks -f value | grep "$1")
        echo "$green Project\t:" $project_show
        if [[ ! -z $instance_show ]]; then echo "$green Instance:" $instance_show; else echo "$red Instance: none"; fi
        echo "$green Network\t:" $check_ip_float
      else
        echo "$green No IP found with" "$1"
      fi
    fi
  fi
}

#instances-list-image
function os-instance-image-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-name' %s\n"
  else
    openstack server list --instance-name "$1"
  fi
}

#instances-list-image
function os-instance-image-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'imageid' or 'image-name' %s\n"
  else
    printf $yellow"List images for this project\n"
    openstack server list --image "$1"
  fi
}

function os-instance-image-list-all() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'imageid' %s\n"
  else
    printf $yellow"List images all projects\n"
    openstack server list --all-projects --image "$1"
  fi
}

#os-instance-show info
function os-instance-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack server show "$1"
    nova diagnostics "$1"
  fi
}

#os-instance-show info
function os-instance-show-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack server show "$1"
    nova diagnostics "$1"
  fi
}

function os-instance-show-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id-list' %s\n"
  else
    check_instances=$(cat instance-id-list)
    echo "$check_instances\n"
    if [[ -z $check_instances ]]; then
      printf "$red instance-id-list does not exist"
    else
      read "response?Are you sure you want to check these instances? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        cat instance-id-list | xargs -n1 openstack server show "$1" | grep -i 'id\|status\|key_name'
        printf "$red Instances check done\n"
      else
        printf "$red Instances check canceled\n"
      fi
    fi
  fi
}

#instance-rename
function os-instance-rename() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'new-instance-name' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      printf "instance does not exist"
      echo "instance does not exist"
    else
      read "response?Are you sure you want to rename the instance to $2? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # no downtime for the instance
        openstack server set --name $2 "$1"
      else
        printf "$red $0 canceled\n"
      fi
    fi
  fi
}

#instance-ip-show info
function os-instance-ip-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'ip-address' %s\n"
  else
    openstack server list --ip "$1"
  fi
}

function os-instance-stop() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    nova stop "$1"
  fi
}

function os-instance-start() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    nova start "$1"
  fi
}

function os-instance-restart-soft() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack server reboot --soft "$1"
  fi
}


function os-instance-restart-hard() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack server reboot --hard "$1"
  fi
}

#instance-migrate info
function os-instance-migrate() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' (block-disk only)\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      printf "instance does not exist"
      echo "empty"
    else
      read "response?Are you sure you want to migrate the instance to a new host? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # openstack server migrate <instance> --block-migration
        instance_move=$(nova live-migration --block-migrate "$1" 2>&1 | head -n 1)
        instance_status=$(echo $instance_move | grep 'ERROR')
        #check instance error
        if [[ $instance_status == *"ERROR"* ]]; then
          echo $yellow"instance-migrate status\n"
          echo "$red $instance_status"
          echo "$red Please use another host."
        else
          echo "$green instance-migrate moved"
          os-instance-show "$1"
        fi
      else
        printf "$red instance-migrate canceled\n"
      fi
    fi
  fi
}

#instance-migrate info
function os-instance-migrate-host() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'hostname' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      printf "instance does not exist"
      echo "empty"
    else
      read "response?Are you sure you want to migrate the instance to a new host? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        instance_move=$(nova live-migration --block-migrate "$1" $2 2>&1 | head -n 1)
        instance_status=$(echo $instance_move | grep 'ERROR')
        #check instance status
        if [[ $instance_status == *"ERROR"* ]]; then
          echo $yellow"instance-migrate status\n"
          echo "$red $instance_status"
          echo "$red Please use another host."
        else
          echo "$green instance-migrate moved"
          os-instance-show "$1"
        fi
      else
        printf "$red instance-migrate canceled\n"
      fi
    fi
  fi
}

function os-instance-keypair-add() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id or instance-name' 'keypair' %s\n"
  else
    #  ssh to instance
    #  add keypair
    echo "test"
  fi
}

#os-instance-show info
function os-instance-console-log() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack console log show "$1"
  fi
}

function os-instance-console-url() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack console url show "$1"
  fi
}

function os-instance-snapshot-list() {
  if [[ ("$#" -lt 0) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    openstack volume snapshot list
  fi
}

function os-instance-snapshot-create() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      printf "instance does not exist"
    else
      read "response?Are you sure you want to create a snapshot? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        datum=$(date +'%Y-%m-%d')
        a=$datum
        b='snapshot'
        snapshot_name="${a}_${b}_"$1""
        # nova image-create --poll "$1" $snapshot_name
        openstack server image create --name $snapshot_name "$1"
        printf $yellow"Snapshotting instance "$1" %s\n"
      else
        printf "$red Snapshot canceled\n"
      fi
    fi
  fi
}

function os-instance-backup-create() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      printf "instance does not exist"
    else
      read "response?Are you sure you want to create a backup? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        datum=$(date +'%Y-%m-%d')
        a=$datum
        b='backup'
        backup_name="${a}_${b}_"$1""
        # nova image-create --poll "$1" $snapshot_name
        openstack server backup create --name $backup_name --wait "$1"
        printf $yellow"Snapshotting instance "$1" %s\n"
      else
        printf "$red Snapshot canceled\n"
      fi
    fi
  fi
}

#allen voor jou dev
# instance create
# - if security groups allows it
# - if the network acl allows ot only for the cloud-prod
# - use the canary has a jump host
# complete -W "test mysql" instance-create
function os-instance-create() {
  # set -x
  if [[ ("$#" -lt 4) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'ams1' 'dev' 'centos' 'instance' %s\n"
    printf "$blue Usage: $0 'ams1' 'dev' 'ubuntu' 'instance' %s\n"
    printf "$blue Usage: $0 'region' 'cloud-nonprod' 'centos' 'instance-name' %s\n"
    printf "$blue Usage: $0 'region' 'cloud-nonprod' 'ubuntu' 'instance-name' %s\n"
    printf "$blue Usage: $0 'region' 'cloud-nonprod' 'centos' 'instance-name' 'zone' 'host' %s\n"
    printf "$blue Usage: $0 'region' 'cloud-nonprod' 'centos' 'instance-name' 'zone' 'host' %s\n"
  else
    if [[ ($2 == "dev") ]]; then
      read "response?Are you sure you want to create this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        os-env "$1" $2-$LDAP_USERNAME
        flavor_id="0030"
        if [[ ($3 == "centos") ]]; then
          image="ecg-centos-7"
        elif [[ ($3 == "ubuntu") ]]; then
          image="ecg-ubuntu-bionic"
        fi
        network_id="27300fa7-3adc-40f3-8cb7-a71c6cb759d5"
        instance="$4"
        mykeypair=$LDAP_USERNAME
        nova boot $instance --key-name $mykeypair --flavor $flavor_id --image $image --nic net-id=$network_id
        printf "$green Instance $4 has been created\n"
        os-instance-list
      else
        printf "$red Instance create canceled\n"
      fi
    elif [[ ($2 == "cloud-nonprod") ]]; then
      read "response?Are you sure you want to create this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [[ ("$1" == "ams1") ]]; then
          region="ams1"
        elif [[ ("$1" == "dus1") ]]; then
          region="dus1"
        fi
        os-env $region $2
        flavor_id="0010"
        if [[ ($3 == "centos") ]]; then
          image="ecg-centos-7"
        elif [[ ($3 == "ubuntu") ]]; then
          image="ecg-ubuntu-bionic"
        fi
        if [[ ("$1" == "ams1") ]]; then
          network_id="76b85c8c-60ad-4a41-88e0-3c45b489d557"
        elif [[ ("$1" == "dus1") ]]; then
          network_id="b2c745f2-c045-42fe-b7a0-2a41f8dcebf1"
        fi
        instance="$4"
        mykeypair=$LDAP_USERNAME
        nova boot $instance --key-name $mykeypair --flavor $flavor_id --image $image --nic net-id=$network_id
        printf "$green Instance $4 has been created\n"
        os-instance-list
      else
        printf "$red Instance create canceled\n"
      fi
    elif [[ ($2 == "cloud-nonprod") && ($6 == "hostname") ]]; then
      read "response?Are you sure you want to create this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [[ ("$1" == "ams1") ]]; then
          region="ams1"
        elif [[ ("$1" == "dus1") ]]; then
          region="dus1"
        fi
        os-env $region $2
        flavor_id="0010"
        if [[ ($3 == "centos") ]]; then
          image="ecg-centos-7"
        elif [[ ($3 == "ubuntu") ]]; then
          image="ecg-ubuntu-bionic"
        fi
        if [[ ("$1" == "ams1") ]]; then
          network_id="76b85c8c-60ad-4a41-88e0-3c45b489d557"
        elif [[ ("$1" == "dus1") ]]; then
          network_id="b2c745f2-c045-42fe-b7a0-2a41f8dcebf1"
        fi
        instance="$4"
        mykeypair=$LDAP_USERNAME
        zone="$5"
        hostname="$6"
        nova boot $instance --key-name $mykeypair --flavor $flavorid --image $imageid --nic net-id=$networkid --availability-zone $zone:$host
        printf "$green Instance $4 has been created\n"
        os-instance-list
      else
        printf "$red Instance create canceled\n"
      fi
    fi
  fi
}

function os-instance-reset() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    check_instance_reset=$(os-instance-show "$1")
    echo "$check_instance_reset\n"
    if [[ -z $check_instance_reset ]]; then
      echo "empty"
    else
      read "response?Are you sure you want to reset this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        nova reset-state --active "$1"
        printf "$red Instance "$1" has been reset\n"
      else
        printf "$red Instance reset canceled\n"
      fi
    fi
  fi
}

function os-instance-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      echo "empty"
    else
      read "response?Are you sure you want to delete this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        #delete
        nova delete "$1"
        # nova force-delete "$1"
        printf "$red Instance "$1" has been deleted\n"
      else
        printf "$red Instance delete canceled\n"
      fi
    fi
  fi
}

function os-instance-delete-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'dev' %s\n"
    printf "$blue Usage: $0 'instance-id-list' %s\n"
  else
    if [[ "$1" == "dev" ]]; then
      os-env ams1 dev-$USER
      printf $yellow"\n"
      set-user $USER
      printf $yellow"\n"
      read "response?Are you sure you want to delete all your dev instances? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        openstack server list -f value -c ID | xargs -n1 openstack server delete &
        pid=$!
        wait $pid
        printf "$red Instances have been deleted\n"
      else
        printf "$red Instances delete canceled\n"
      fi
      #cleanup secutity groups also
      #if security group fails you need to delete the security group rules
    else
      check_instances=$(cat instance-id-list)
      echo "$check_instances\n"
      if [[ -z $check_instances ]]; then
        printf "$red instance-id-list does not exist"
      else
        read "response?Are you sure you want to delete this instances? [y/N]?"
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
          cat instance-id-list | xargs -n1 openstack server delete
          rm -rf instance-id-list
          printf "$red Instances have been deleted\n"
        else
          printf "$red Instances delete canceled\n"
        fi
      fi
    fi
  fi
}

function os-instance-delete-stuck() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' or 'instance-name' %s\n"
  else
    check_instance=$(os-instance-show "$1")
    echo "$check_instance\n"
    if [[ -z $check_instance ]]; then
      echo "empty"
      # https://maestropandy.wordpress.com/2016/06/30/openstack-delete-error-state-instances/
    else
      read "response?Are you sure you want to delete this instance? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        #delete
        nova reset-state --active "$1"
        nova delete "$1"
        printf "$red Instance "$1" has been deleted\n"
      else
        printf "$red Instance delete canceled\n"
      fi
    fi
  fi
}

function os-instance-volume-resize() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'volume-id' 'size GB' %s\n"
  else
    read "response?Are you sure you want to resize this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      #first we have to dettach it from the server
      openstack server remove volume "$1" $2
      # we resize the volume
      openstack volume set $2 --size $3
    else
      printf "$red Volume resize canceled\n"
    fi
  fi
}

function os-instance-volume-attach() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'volume-id' %s\n"
  else
    read "response?Are you sure you want to attach this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack server add volume "$1" $2 --device /dev/vdb
      openstack volume show $2
    else
      printf "$red Volume attach canceled\n"
    fi
  fi
}

function os-instance-volume-detach() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'volume-id' \n"
  else
    read "response?Are you sure you want to detach this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack server add volume "$1" $2 --device /dev/vdb
      openstack volume show $2
    else
      printf "$red Volume detach canceled\n"
    fi
  fi
}
# function os-instance-error-reset2() {
#   if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#       printf "$blue Usage: instance-error-reset 'instance-id' or 'instance-name' %s\n"
#   else
#     check_instance_reset=$(os-instance-show "$1")
#     echo "$check_instance_reset\n"
#     if [[ -z $check_instance_reset ]]; then
#         # instance does not exist
#     else
#         read "response?Are you sure you want to reset this instance? [y/N]?"
#         if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
#             #delete
#             nova reset-state --active $3
#             nova reset-state --all-tenants
#             # nova delete "$1"
#             # nova force-delete "$1"
#             # if error
#             #check status nova scheduler in compute
#             #nova service list --compute
#             # nova service-list --host $hostname  if disabled that is why its failing
#             printf "$red Instance "$1" has been reset\n"
#         else
#             printf "$red Instance reset canceled\n"
#         fi
#     fi
#   fi
# }
