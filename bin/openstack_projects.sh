#!/usr/bin/env bash

#####################################################################
# script openstack_rc - projects                                     #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#PROJECT=============================================================================================================#

#project-list
function os-project-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    openstack project list --sort-column Name
  else
    for project in "$@"; do
      echo "List: $project\n"
      openstack project list --sort-column Name | grep -i $project
    done
  fi
}

function os-project-security-group-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-security-group-list 'projectid' or 'projectname' %s\n"
  else
    echo "$purple List: $1 security groups\n"
    list_sg=$(openstack security group list --project $1)
    echo $green$list_sg"\n"
    list_sg_id_result=$(openstack security group list -f value --project $1 -c ID)
    echo $list_sg_id_result | while IFS= read -r sg_id; do
      sg_result=$(openstack security group show $sg_id | grep -w 'id\|name\|rules\|direction\|ethertype\|port_range_\|protocol\|remote_ip' | tr '",' ' ')
      echo $green$sg_result"\n"
    done
  fi
}

function os-project-security-group-delete() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-security-group-delete 'projectname' 'securitygroup' %s\n"
  else
    echo "$purple List: security groups $1 %s\n"
    list_sg=$(openstack security group list -f value --project $1 -c ID -c Name -c Project)
    echo $green$list_sg"\n"
    echo "$purple Delete: security group $2\n"
    list_sg_id=$(echo $list_sg | grep $2 | awk '{print $1}')
    echo "$list_sg_id" | while IFS= read -r sg_id; do
      echo "$green Deleting: $sg_id\n"
      # openstack security group delete $sg_id
    done
  fi
}

function os-project-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'project-id' or 'project-name' %s\n"
  else
    check_project=$(os-project-set "$1")
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      project=$(openstack project show $1 -f json | grep -w 'id\|name' | tr '",' ' ')
      projectid=$(echo "$project" -f value | grep -w 'id' | awk 'NR == 1 {print $3}')
      project_quota=$(openstack quota show $projectid -f json | grep -w 'id\|project_name\|cores\|ram\|gigabytes\|volumes\|region_name\|secgroup-rules\|secgroups\|server-group-members\|server-groups' | tr '",' ' ')
      project_show_region=$(echo "$project_quota" | awk 'NR == 4 {print $1"\t"$2" "$3}')
      project_show_id=$(echo "$project_quota" | awk 'NR == 5 {print $1"\t\t"$2" "$3}')
      project_show_name=$(echo "$project_quota" | awk 'NR == 7 {print $1"\t"$2" "$3}')
      project_show_cores=$(echo "$project_quota" | awk 'NR == 2 {print $1"\t\t"$2" "$3}')
      project_show_ram=$(echo "$project_quota" | awk 'NR == 8 {print $1"\t\t"$2" "$3}')
      project_show_volume=$(echo "$project_quota" | awk 'NR == 3 {print $1"\t"$2" "$3}')
      project_show_secgroup_rules=$(echo "$project_quota" | awk 'NR == 9 {print $1"\t\t"$2" "$3}')
      project_show_secgroups=$(echo "$project_quota" | awk 'NR == 10 {print $1"\t\t"$2" "$3}')
      project_show_groups=$(echo "$project_quota" | awk 'NR == 12 {print $1"\t\t"$2" "$3}')
      project_show_group_members=$(echo "$project_quota" | awk 'NR == 11 {print $1"\t"$2" "$3}')
      #project usage
      project_usage_limits=$(nova limits --tenant $projectid | grep -wi 'name\|cores\|ram' | tr '|-+' ' ' | column -t)
      #disk usage
      #cinder quota-usage project-id
      #openstack quota list --volume --project  project_id
      project_usage_volume=$(cinder quota-usage $projectid | grep -wi 'type\|gigabytes' | tr '|' ' ' | awk 'NR==2 {print $1, $2, $4}' | column -t)
      #swift usage
      # project_usage_swift=$(openstack object store account show) or swift --os-project-id $project_id stat
      project_usage_swift=$(swift --os-project-id $projectid stat --lh | grep -w 'Bytes:\|Objects:\|Containers:\|Quota-Bytes:' | tr ':' ' ' | column -t)
      project_show_swift_container=$(echo "$project_usage_swift" | awk 'NR == 1 {print $1"\t"$2}')
      project_show_swift_objects=$(echo "$project_usage_swift" | awk 'NR == 2 {print $1"\t\t"$2}')
      project_show_swift_used=$(echo "$project_usage_swift" | awk 'NR == 3 {print $1"\t"$2}')
      project_show_swift_max=$(echo "$project_usage_swift" | awk 'NR == 4 {print $2"\t"$3}')
      #quota show
      printf "$purple \nProject: $1 quota\n"
      printf "$green$project_show_region\n"
      printf "$green$project_show_id\n"
      printf "$green$project_show_name\n"
      printf "$green$project_show_cores\n"
      printf "$green$project_show_ram\n"
      printf "$green$project_show_volume\n"
      printf "$green$project_show_secgroups\n"
      printf "$green$project_show_secgroup_rules\n"
      printf "$green$project_show_groups\n"
      printf "$green$project_show_group_members\n\n"
      #cpu mem usage
      printf $yellow"cpu,ram usage:\n"
      printf "$green$project_usage_limits\n\n"
      #volume usage
      printf $yellow"volume usage:\n"
      printf "$green$project_usage_volume\n\n"
      #swift usage
      printf $yellow"swift usage:\n"
      printf "$green$project_show_swift_container\n"
      printf "$green$project_show_swift_objects\n"
      printf "Used $green$project_show_swift_used\n"
      printf "Max $green$project_show_swift_max\n"
      # printf "%-30s | %-30s | %-30s" "$project_show_swift_container" "$project_show_swift_objects" "$project_show_swift_used" "$project_show_swift_max" >> test.txt
    fi
  fi
}
#INSTANCES===================================================================================================================================================================#

function os-project-instances-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'project-id' or 'project-name' %s\n"
  elif [ "$#" -eq 0 ]; then
    os-instance-list
  else
    os-instance-list $1
  fi
}

function os-project-instances-start() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-instances-start or 'project-id' or 'project-name' %s\n"
  else
    echo "$purple Project $1 list instances:\n"
    openstack server list -f value --long --project $1
    read "response?Are you sure you want to start all instances? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      instances=$(openstack server list -f value --long --project $1 -c ID)
      echo $instances | while IFS= read -r instance; do
        printf $yellow"\n start instance: $instance\n"
        nova start $instance
        printf "$green instance: $instance started\n"
      done
    else
      printf "$red instance: $instance start canceled\n"
    fi
  fi
}

function os-project-instances-stop() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-instances-stop or 'project-id' or 'project-name' %s\n"
  else
    echo "$purple Project $1 list instances:\n"
    openstack server list -f value --long --project $1
    read "response?Are you sure you want to stop all instances? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      instances=$(openstack server list -f value --long --project $1 -c ID)
      echo $instances | while IFS= read -r instance; do
        printf $yellow"\n stop instance: $instance\n"
        nova stop $instance
        printf "$green Project $1 instance: $instance stopped\n"
      done
    else
      printf "$red Project $1 instance: $instance stopped canceled\n"
    fi
  fi
}

function os-project-instances-stop-all() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'project-id' or 'project-name' %s\n"
  else
    printf $yellow"Checking project: $1 instances' %s\n"
    os-instance-list $1
    read "response?Are you sure you want to stop all instances? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      #delete
      openstack server list --project $1 -f value -c ID | xargs -n1 nova stop
      printf "$red all instances on $1 have been stopped \n"
    else
      printf "$red instances stop canceled\n"
    fi
  fi
}

function os-project-instances-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-instances-delete or 'project-id' or 'project-name' %s\n"
  else
    echo "$purple Project $1 list instances:\n"
    openstack server list -f value --long --project $1
    read "response?Are you sure you want to delete all instances? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      instances=$(openstack server list -f value --long --project $1 -c ID)
      echo $instances | while IFS= read -r instance; do
        printf $yellow"\n delete instance: $instance\n"
        nova delete $instance
        printf "$green instance: $instance deleted\n"
      done
    else
      printf "$red instance: $instance delete canceled\n"
    fi
  fi
}

function os-project-instances-delete-all() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'project-id' or 'project-name' %s\n"
  else
    printf $yellow"Checking project: $1 instances' %s\n"
    os-instance-list $1
    read "response?Are you sure you want to delete all instances? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      #delete
      openstack server list --project $1 -f value -c ID | xargs -n1 openstack server delete
      printf "$red Instance $1 has been deleted\n"
    else
      printf "$red Instance delete canceled\n"
    fi
  fi
}

#NETWORK===================================================================================================================================================================#

function os-project-network-subnet-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: network-show-fip 'projectname or projectid'.\n"
  else
    openstack subnet list --project $1
    openstack subnet list --project $1 -f value | wc -l
  fi
}

function os-project-network-fip-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: network-show-fip 'projectname or projectid'.\n"
  else
    openstack floating ip list --project $1
  fi
}

# function os-project-network-ip-list() {
#   if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
#     printf "$blue Usage: project-network-ip-list 'projectname or projectid' 'network'.\n"
#   else
#       # openstack subnet list --project $1 --network
#       # check if project network has enough ip's left
#   fi
# }

#network-list-project
function os-project-network-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-network-show or 'project-id' or 'project-name' %s\n"
  else
    check_project=$(os-project-set "$1")
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      # echo "$purple Project\t:" $1
      result_network=$(openstack network list -f value --project $1)
      # misschien die u' ook trimmen ?
      network_id_result=$(echo "$result_network" | awk '{print $1}' | tr -d "[]'")
      subnet_id_result=$(echo "$result_network" | awk '{print $3}' | tr -d "[]'")
      echo "$green Networks:\t\n"$result_network"\n"
      # echo $yellow"Checking each Network"
      echo $subnet_id_result | while IFS= read -r subnet_id; do
        subnet=$(neutron subnet-show $subnet_id -f json | grep -w 'name\|network_id' | tr '",' ' ')
        instances=$(openstack port list --project $1 -f value -c ID -c Name -c Status -c 'Fixed IP Addresses')
        instances_up=$(echo $instances | grep $subnet_id | grep 'ACTIVE' | grep -vF "[]")
        instances_down=$(echo $instances | grep $subnet_id | grep 'DOWN' | grep -F "[]")
        instances_count=$(echo $instances | wc -l)
        instances_count_down=$(echo $instances_down | wc -l)
        instances_count_up=$(echo $instances_up | wc -l)
        #instances
        echo $yellow"\nNetwork\t:"$subnet_id
        echo $yellow"Subnet\t:\n" $subnet"\n"
        # echo "$green Instances up for this network:\n"$instances"\n"
        echo "$green Instances up for this network:\n"$instances_up"\n"
        echo "$red Instances down for this network:\n"$instances_down"\n\n"
        #numbers
        echo "$green Instance ip's total\t:"$instances_count
        echo "$green Instance ip's up\t:"$instances_count_up
        echo "$red Instance ip's down\t:"$instances_count_down"\n"
      done
    fi
  fi
}

#QOUTA===================================================================================================================================================================#

# project-set-qouta
function os-project-qouta-set() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf $yellow"This is only for dev environments' %s\n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'cores' 'value' %s\n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'ram' 'value in GB' %s\n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'volume' 'value' \n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'swift' 'value' \n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'secgroup-rules' 'value' \n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'secgroups' 'value' \n"
    printf "$blue Usage: project-qouta-set 'project-id/project-name' 'server-groups-all' 'value' \n"
  else
    # check if project exists
    check_project=$(os-project-set "$1")
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      printf "Project Update: $1 $2: $3\n"
      read "response?Are you sure you want to edit this dev-project? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [[ $2 == "cores" ]]; then
          printf "change project: $1 cores: $3 vcpu\n"
          # $openstack quota set --cores 50  <project-name>
          openstack quota set --cores $3 $1
          os-project-show $1
          echo "$check_project\n"
        elif [[ $2 == "ram" ]]; then
          printf "change project: $1 ram: $3 GB\n"
          memory=$(($3 * 1000))
          echo "Actual ram value: $memory"
          openstack quota set --ram $memory $1
          os-project-show $1
          echo "$check_project\n"
        elif [[ $2 == "volume" ]]; then
          printf "change project: $1 volume-gigabytes: $3 \n"
          # cinder quota-update --quotaName NewValue tenantID
          # cinder quota-update --gigabytes $3 $1
          openstack quota set --gigabytes $3 $1
          os-project-show $1
        elif [[ $2 == "swift" ]]; then
          printf "change project: $1 swift-object-gigabytes: $3 \n"
          swift post -m quota-bytes:$3
        elif [[ $2 == "secgroup-rules" ]]; then
          printf "change project: $1 secgroup-rules: $3 \n"
          openstack quota set --secgroup-rules $3 $1
          os-project-show $1
        elif [[ $2 == "secgroups" ]]; then
          printf "change project: $1 secgroups: $3 \n"
          openstack quota set --secgroups $3 $1
          os-project-show $1
        elif [[ $2 == "server-groups-all" ]]; then
          printf "change project: $1 server-group-members: $3 \n"
          printf "change project: $1 server-groups: $3 \n"
          openstack quota set --server-group-members $3 $1
          openstack quota set --server-groups $3 $1
          os-project-show $1
        else
          printf "error.\n"
        fi
      else
        printf "$red Change project canceled\n"
      fi
    fi
  fi
}

function os-project-dev-fixdev() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'username' \n"
  else
    echo "fix dev-$1 on osevents-0217.ams1.cloud.ecg.so"
    # python fix_makedev.py <username>
    ssh -t "osevents-0217.ams1.cloud.ecg.so" "sudo python fix_makedev.py $1"
  fi
}

function os-project-dev-remove-resources() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf $yellow"This is only for dev environments' %s\n"
    printf "project-delete-resources 'region' 'projectname' %s\n"
  else
    # check if project exists
    check_project=$(os-env-set $1 $2)
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      # os-project-show $2
      read "response?Are you sure you want to remove all resources from this dev-project? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        printf $yellow"\nCleanup Project: $2\n"
        # # delete all instances
        printf "remove all instances\n"
        openstack server list --project $2 -c ID -f value | xargs -n1 openstack server delete &
        pid=$!
        wait $pid
        # wait and check to see if all instances are delete
        sleep 10
        #change ram to 0
        printf "remove all ram\n"
        openstack quota set --ram 0 $2 &
        pid=$!
        wait $pid
        #change cores to 0
        printf "remove all cores\n"
        openstack quota set --cores 0 $2 &
        pid=$!
        wait $pid
        #change volume to 0
        printf "remove all volumes\n"
        openstack quota set --gigabytes 0 $2 &
        pid=$!
        wait $pid
        printf "remove all swift\n"
        #delete swift containers
        check_swift=$(swift list)
        echo $check_swift | while read -r line; do
          swift delete $line &
          pid=$!
          wait $pid
        done
        #change swift to 0
        swift post -m quota-bytes:0 &
        pid=$!
        wait $pid
        os-project-show $2
      else
        printf "$red Change project canceled\n"
      fi
    fi
  fi
}

function os-project-dev-remove-resources-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf $yellow"This is only for dev environments' %s\n"
    printf "project-delete-resources 'projectname' %s\n"
  else
    # check if project exists
    os-env-set ams1 $1
    check_project=$(os-env-set ams1 $1)
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      os-project-show $1
      read "response?Are you sure you want to remove all resources form this dev-project? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        printf "$red \nCleanup Project: $1 %s\n"
        # delete all instances
        printf "remove all instances\n"
        openstack server list --project $1 -c ID -f value | xargs -n1 openstack server delete &
        pid=$!
        wait $pid
        # wait and check to see if all instances are delete
        # sleep 10
        #change ram to 0
        printf "remove all ram\n"
        openstack quota set --ram 0 $1 &
        pid=$!
        wait $pid
        #change cores to 0
        printf "remove all cores\n"
        openstack quota set --cores 0 $1 &
        pid=$!
        wait $pid
        #change volume to 0
        printf "remove all volumes\n"
        openstack quota set --gigabytes 0 $1 &
        pid=$!
        wait $pid
        printf "remove all swift\n"
        #delete swift containers
        check_swift=$(swift list)
        echo $check_swift | while read -r line; do
          swift delete $line &
          pid=$!
          wait $pid
        done
        #change swift to 0
        swift post -m quota-bytes:0 &
        pid=$!
        wait $pid
        # openstack project delete $project & pid=$!
        # wait $pid
        os-project-show $1
      else
        printf "$red Change project canceled\n"
      fi
    fi
  fi
}

function os-project-dev-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf $yellow"This is only for dev environments' %s\n"
    printf "project-dev-delete 'projectname' %s\n"
  else
    os-env-set ams1 $1
    check_project=$(os-env-set ams1 $1)
    echo "$check_project\n"
    if [[ -z $check_project ]]; then
    #project does not exist
    else
      os-project-show $1
      projects=$(openstack project list --long -c Name -f value | grep $1)
      for project in $projects; do
        echo Project: $project
        read "response?Are you sure you want to delete this project? [y/N]?"
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
          openstack project delete $project
          printf "$green Project $project has been deleted\n"
        else
          printf "$red project delete canceled\n"
        fi
      done
    fi
  fi
}

function os-project-dev-delete-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf $yellow"This is only for dev environments' %s\n"
    printf "Are you sure you want to delete? y/n\n"
  else
    if [[ ("$1" == "y") ]]; then
      project_result=$(openstack project list --long -c Name -f value | grep dev- | head -342)
      echo $project_result | while read -r project_name; do
        os-env-set ams2 $project_name
        printf $yellow"deleting Project: $project_name\n"
        openstack project delete $project_name
        printf "$green Project: $project_name has been deleted\n"
      done
    else
      printf "$red project delete canceled\n"
    fi
  fi
}

function os-project_dev_user_check.sh() {
  #For loop
  for user in $(cat move_userlist); do
    echo $user
    #set env username
    os-env-set ams1 $user
    #list servers
    # server_list=$(openstack server list --long)
    server_list=$(openstack server list --long -f csv)
    echo $server_list
    #merge (username+serverlist) and add to file
    printf '%-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n' "$user" "$server_list" >>"$HOME/users_instances.csv"
  done
}

#STORAGE-swift-object-gigabytes===================================================================================================================================================================#

function os-project-swift-stat() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    swift stat --lh
  else
    for project in "$@"; do
      echo "List: $project\n"
      swift stat --os-project-name $project --lh
    done
  fi
}

function os-project-swift-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    swift list --lh
  else
    for project in "$@"; do
      echo "List: $project\n"
      swift list --os-project-name $project --lh
    done
  fi
}

function os-project-swift-list-container() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    swift list $2 --lh --versions
  else
    for project in "$@"; do
      echo "List: $project\n"
      swift list $2 --os-project-name $project --lh --versions
    done
  fi
}

function os-project-container-list() {
  # if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 \n"
  else
    printf $yellow"Listing all containers (default: 1000)"
    openstack container list --all
  fi
}

function os-project-container-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'container-name' %s\n"
  else
    openstack container show $1
  fi
}

# project-swift-copy() {

# }

function os-project-swift-delete() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-swift-delete 'region' 'project-name' %s\n"
  else
    os-env-set $1 $2
    check_swift=$(swift list)
    read "response?Are you sure you want to delete all files? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo $check_swift | while read -r line; do
        swift delete $line &
        pid=$!
        wait $pid
      done
      #change swift to 0
      swift post -m quota-bytes:0 &
      pid=$!
      wait $pid
      os-project-show $2
    else
      printf "$red Swift delete canceled\n"
    fi
  fi
}

function os-project-swift-download() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'container' 'file' %s\n"
  else
    read "response?Are you sure you want to download this file? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      # swift upload mycontainer myfile.txt
      swift download $1 $2
    else
      printf "$red Swift download canceled\n"
    fi
  fi
}

#swift upload
function os-project-swift-upload() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'n(normal)/c(chunks)' 'container' 'file' %s\n"
  else
    read "response?Are you sure you want to upload this file? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      printf $yellow"Swift upload normal\n"
      # swift upload normal
      if [[ "n" == "$1" ]]; then
        swift upload $2 $3
      #swift upload chunks
      elif [[ "c" == "$1" ]]; then
        printf $yellow"Swift upload in chunks of 64\n"
        swift upload -S 64 $1 $2
      fi
    else
      printf "$red Swift upload canceled\n"
    fi
  fi
}

#STORAGE-volume-gigabytes===================================================================================================================================================================#
function os-project-volume-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    openstack volume list
  else
    for project in "$@"; do
      echo "List: $project\n"
      openstack volume list --project $project
    done
  fi
}

function os-project-volume-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'projectid' %s\n"
  else
    #show if volumes are used by the project of not even though they are available
    #openstack quota list --volume --project project_id
    openstack quota list --volume --project $1
  fi
}

function os-project-volume-create() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-name/project-id' 'volume-name' 'size GB' %s\n"
  else
    #Cinder uses default_volume_type which is defined in cinder.conf during volume creation. default_volume_type = lvmdriver-1
    #check: openstack availability zone list
    read "response?Are you sure you want to create this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack volume create --size $3 --project $1 --availability-zone nova $2
    else
      printf "$red Volume create canceled\n"
    fi
  fi
}

function os-project-volume-delete() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-volume-delete 'project-name/project-id' 'volume-name' %s\n"
  else
    read "response?Are you sure you want to delete this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack volume delete $1 $2
    else
      printf "$red Volume delete canceled\n"
    fi
  fi
}

function os-project-volume-delete-all() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-volume-delete-all 'project-name/project-id' 'volume-name' %s\n"
  else
    read "response?Are you sure you want to delete this volume? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack volume delete $1 $2
    else
      printf "$red Volume delete canceled\n"
    fi
  fi
}

# STORAGE-volume-snapshot===================================================================================================================================================================#

function os-project-snapshot-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    openstack volume snapshot list
  else
    for project in "$@"; do
      echo "List: $project\n"
      openstack volume snapshot list --project $project
    done
  fi
}
# keypair===================================================================================================================================================================#

function os-keypair-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: keypair-list\n"
  else
    openstack keypair list
  fi
}

function os-keypair-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: keypair-show 'username' %s\n"
  else
    openstack keypair show $1
  fi
}

function os-keypair-create() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'username' %s\n"
  else
    keypair="~/.ssh/id_ed25519.pub"
    echo "the following key will be used:" $keypair
    read "response?Are you sure you want to create this keypair? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack keypair create --public-key $keypair $1
    else
      printf "$red keypair: $1 create canceled\n"
    fi
  fi
}

function os-keypair-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: keypair-delete 'username' %s\n"
  else
    read "response?Are you sure you want to delete this keypair? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack keypair delete $1
    else
      printf "$red keypair: $1 delete canceled\n"
    fi
  fi
}
