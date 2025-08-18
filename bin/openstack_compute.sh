#!/usr/bin/env bash

#####################################################################
# script openstack_rc - hypervisors                                 #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#1.COMPUTE ===========================================================================================================#

function os-compute-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'hypervisorname' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    #hypervisors
    compute_result=$(openstack compute service list --sort Hypervisor --long)
    compute_all=$(echo "$compute_result")
    compute_all_aantal=$(echo "$compute_result" | wc -l | head -n 1)
    compute_up=$(echo "$compute_result" | grep -w 'enabled')
    compute_up_aantal=$(echo "$compute_result" | grep -w 'enabled' | wc -l | head -n 1)
    compute_down=$(echo "$compute_result" | grep -w 'disabled')
    compute_down_aantal=$(echo "$compute_result" | grep -w 'disabled' | wc -l | head -n 1)
    aggregates_dedicated=$(openstack aggregate show dedicated | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
    aggregates_dedicated_aantal=$(echo "$aggregates_dedicated" | wc -l | head -n 1)
    aggregates_shared=$(openstack aggregate show shared | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
    aggregates_shared_aantal=$(echo "$aggregates_shared" | wc -l | head -n 1)
    aggregates_testing=$(openstack aggregate show testing | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
    aggregates_testing_aantal=$(echo "$aggregates_testing" | wc -l | head -n 1)
    aggregates_spare=$(openstack aggregate show spare | grep hosts | awk '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | tr -d ',' | tr -d '|' | sed 's/hosts/ /g' | sed '/^[[:space:]]*$/d')
    aggregates_spare_aantal=$(echo "$aggregates_spare" | wc -l | head -n 1)
    # print computes
    printf $yellow"List Computes\n"
    printf "$purple compute-all:\n"
    printf $purple$compute_all"\n"
    printf "$green compute-up:\n"$green$compute_up"\n"
    printf "$red compute-down:\n"$red$compute_down"\n"
    # print Aggregates
    printf $yellow"List Aggregates\n"
    printf "$green aggregates-dedicated\t:\n"$aggregates_dedicated"\n"
    printf "$green aggregates-shared\t:\n"$aggregates_shared"\n"
    printf "$green aggregates-testing\t:\n"$aggregates_testing"\n"
    printf "$green aggregates-spare\t:\n"$aggregates_spare"\n"
    # print amount computes
    printf $yellow"Computes\n"
    printf "$purple compute-all\t:"$purple$compute_all_aantal"\n"
    printf "$green compute-up\t:"$green$compute_up_aantal"\n"
    printf "$red compute-down\t:"$red$compute_down_aantal"\n"
    # printf $white"hosts\t:\n"$host_all_aantal"\n"
    # print amount aggregates
    printf $yellow"Aggregates\n"
    printf "$green aggregates-dedicated\t:"$aggregates_dedicated_aantal"\n"
    printf "$green aggregates-shared\t:"$aggregates_shared_aantal"\n"
    printf "$red aggregates-testing\t:"$aggregates_testing_aantal"\n"
    printf "$red aggregates-spare\t:"$aggregates_spare_aantal"\n"
  else
    for hypervisor in "$@"; do
      printf "$green List compute:\n"$hypervisor
      openstack compute service list --long --host $hypervisor
    done
  fi
}

function os-compute-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'hostname' %s\n"
  else
    printf $yellow"checking: "$1"\n"
    openstack compute service list --service nova-compute --host $1
  fi
}

function os-compute-enable() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'hostname' %s\n"
  else
    printf $yellow"Compute check: "$1"\n"
    openstack compute service list --service nova-compute --host $1
    read "response?Do you want to enable the nova-scheduler on this compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack compute service set --enable $1 nova-compute
      printf "$green Compute enabled: "$1"\n"
      compute-list | grep $1 | head -n 1
    else
      printf "$red compute enable canceled\n"
    fi
  fi
}

function os-compute-disable() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'hostname' 'reason' %s\n"
  else
    printf $yellow"Compute check: "$1"\n"
    openstack compute service list --service nova-compute --host $1
    read "response?Do you want to disable the nova-scheduler on this compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack compute service set --disable --disable-reason "$2" $1 nova-compute
      printf "$red Compute disabled: "$1"\n"
      compute-list | grep $1 | head -n 1
    else
      printf "$red compute disable canceled\n"
    fi
  fi
}

function os-compute-instance-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    echo "$blue Usage: compute-instance-list\n"
    echo "$blue Usage: compute-instance-list 'hypervisorname' or 'multiple' %s\n"
    echo "$blue Usage: compute-instance-list 'multiple hypervisornames' %s\n"
  elif [ "$#" -eq 0 ]; then
    openstack server list --all-projects
  else
    for host in "$@"; do
      # instance_list=$(openstack server list --long --all-projects --host $host -c ID -c Name)
      instance_list=$(nova list --all-tenants --host $host --fields id,name,tenant_id,status,OS-EXT-SRV-ATTR:host | tail -n +4 | tail -r | tail -n +2 | tail -r)
      instance_amount=$(echo "$instance_list" | wc -l)
      echo $yellow"Checking: $host\n"
      echo "$green Instances list: \n"$instance_list"\n"
      echo "Instances amount:"$instance_amount
    done
  fi
}

function os-compute-instance-start() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 hostname\n"
  else
    for hostname in "$@"; do
      #list instances on hv
      echo "List: $hostname instances"
      check_instances=$(openstack server list --long --all-projects -c ID -c Name -c Status -c 'Power State' -c Networks --host $hostname)
      echo $check_instances
      check_id=$(echo $check_instances | awk 'NR>2 {print $2}')
      echo $check_id | while read -r instance; do
        nova start $instance
      done
    done
  fi
}

#show usage of hypervisor
function os-compute-usage-show() {
  openstack host show $1
}

function os-compute-aggregate-list() {
  host_list=$(openstack compute service list --long -f value | grep zone | awk '{print $3}')
  for host in $host_list; do
    echo "$host"
    # openstack hypervisor show $i -c aggregates -f shell | awk -F"'" '{print $2,$4}'
  done
}

function os-compute-aggregate-move() {
  if [[ ("$#" -lt 3) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: compute-move 'hostname' 'old-aggregate' 'new-aggregate' %s\n"
  else
    printf $yellow"Compute check: "$1"\n"
    openstack compute service list --service nova-compute --host $1
    read "response?Do you want to move this aggregate from the compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack aggregate remove host $2 $1
      openstack aggregate add host $3 $1
      printf "$green Compute aggregate moved: "$1"\n"
      os-compute-list | grep $1 | head -n 1
    else
      printf "$red compute move canceled\n"
    fi
  fi
}

function os-compute-aggregate-add() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: compute-move 'hostname' 'aggregate' %s\n"
  else
    printf $yellow"Compute check: "$1"\n"
    openstack compute service list --service nova-compute --host $1
    read "response?Do you want to add this aggregate $2 to the compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack aggregate add host $2 $1
      printf "$green Compute aggregate $2 added to "$1"\n"
      os-compute-list | grep $1 | head -n 1
    else
      printf "$red compute add aggregate canceled\n"
    fi
  fi
}

function os-compute-aggregate-remove() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: compute-delete 'hostname' 'old-aggregate' \n"
  else
    printf $yellow"Compute check: "$1"\n"
    openstack compute service list --service nova-compute --host $1
    read "response?Do you want to remove this $2 aggregate from the compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openstack aggregate remove host $2 $1
      printf "$red Compute aggregate $2 removed from "$1"\n"
      os-compute-list | grep $1 | head -n 1
    else
      printf "$red compute aggregate remove canceled\n"
    fi
  fi
}

function os-compute-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'hostname' \n"
  else
    printf $yellow"Compute check: "$1"\n"
    check_compute=$(openstack compute service list -f value --service nova-compute --host $1)
    echo "$check_compute"
    read "response?Do you want to delete this compute? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      compute_id=$(echo "$check_compute" | awk '{print $1}')
      openstack compute service delete $compute_id
      printf "$red Compute deleted: "$1"\n"
      os-compute-list | grep $1 | head -n 1
    else
      printf "$red compute delete canceled\n"
    fi
  fi
}

#2.HOSTS=============================================================================================================#
# host : wijst de hypervisors en nova services die (enabled)

function os-host-rack-instances() {
  # Function will be called
  function get_myfacts() {
    printf "Rack host list: $1 %s\n"
    check_rack=$(sudo hammer --output csv host list --search facts.rack=$1 | awk -F ',' '{print $2}' | grep -v Name)
    echo "$check_rack" >rack_$1_hosts.txt
  }
  # call function from here
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: rack-host-instances.sh 'rack' \n"
  else
    #GET INFO FOREMAN
    rack="$1"
    rack_file="rack_$1_hosts.txt"
    foreman="foreman.ams5.init1.cloud"
    # Execution of the function on the remote machine.
    ssh -t -t $USER@$foreman "$(declare -f get_myfacts);get_myfacts $1"
    #download from remote
    download_file=$(rsync --progress -e ssh $USER@$foreman:/home/$USER/$rack_file $HOME)
    download_result=$(echo "$download_file" | grep '%')
    echo $download_result
    echo "file downloaded: $rack_file"
    #delete from remote
    delete_file=$(ssh $USER@$foreman "rm -rf $rack_file")
    echo $delete_file

    #GET INSTANCES
    rack_dir="rack_$1_hosts"
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

#aggregates
function os-host-aggregate-list() {
  openstack aggregate list
}

#3.HYPERVISORS===================================================================================================================================================================================#

# hypervisor: wijst alleen de hypervisors en niet de nova services
function os-hypervisor-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: compute-show 'hostname\n"
  else
    #check if hv exists
    check_hv=$(openstack hypervisor list -f value | grep $1 | awk '{print $2}')
    # printf $yellow"Hypervisor: $1 %s\n"
    echo $yellow"Hypervisor: "$check_hv"\n"
    if [[ -z $check_hv ]]; then
      printf "$red hypervisor $1 does not exist\n"
    else
      hv_quota=$(openstack hypervisor show $check_hv -f json | grep -w 'service_id\|service_host\|state\|vcpus\|vcpus_used\|memory_mb\|free_ram_mb\|memory_mb_used\|local_gb\|free_disk_gb\|disk_available_least\|local_gb_used\|host_ip\|aggregates' | tr '",' ' ')
      hv_show_id=$(echo "$hv_quota" | awk 'NR == 11 {print $1"\t"$2"\t"$3}')
      hv_show_hostname=$(echo "$hv_quota" | awk 'NR == 10 {print $1"\t"$2"\t"$3}')
      # hv_show_aggregates=$(echo "$hv_quota" | awk 'NR == 1 {print $1"\t"$2"\t"$3}')
      hv_show_state=$(echo "$hv_quota" | awk 'NR == 12 {print $1"\t"$2"\t"$3}')
      hv_show_vcpus=$(echo "$hv_quota" | awk 'NR == 13 {print $1"\t\t"$2"\t"$3}')
      hv_show_vcpu_used=$(echo "$hv_quota" | awk 'NR == 14 {print $1"\t"$2"\t"$3}')
      hv_show_memory=$(echo "$hv_quota" | awk 'NR == 8 {print $1"\t"$2"\t"$3}')
      hv_show_memory_free=$(echo "$hv_quota" | awk 'NR == 4 {print $1"\t"$2"\t"$3}')
      hv_show_memory_used=$(echo "$hv_quota" | awk 'NR == 9 {print $1"\t"$2"\t"$3}')
      hv_show_local_disk=$(echo "$hv_quota" | awk 'NR == 2 {print $1""$2"\t"$3}')
      hv_show_local_disk_free=$(echo "$hv_quota" | awk 'NR == 3 {print $1"\t"$2"\t"$3}')
      hv_show_local_gb=$(echo "$hv_quota" | awk 'NR == 6 {print $1"\t"$2"\t"$3}')
      hv_show_local_gb_used=$(echo "$hv_quota" | awk 'NR == 7 {print $1"\t"$2"\t"$3}')
      hv_show_aggregates=$(openstack hypervisor show $check_hv -f json | jq .'aggregates' | tr '",[]' ' ' | xargs | sed -e 's/ /,/g')
      #hv show
      printf "$green$hv_show_id\n"
      printf "$green$hv_show_hostname\n"
      printf "$green Aggregates\t:\t"$hv_show_aggregates"\n"
      printf "$green$hv_show_vcpus\n"
      printf "$green$hv_show_vcpu_used\n"
      printf "$green$hv_show_memory\n"
      printf "$green$hv_show_memory_free\n"
      printf "$green$hv_show_memory_used\n"
      printf "$green$hv_show_local_disk\n"
      printf "$green$hv_show_local_disk_free\n"
      printf "$green$hv_show_local_gb\n"
      printf "$green$hv_show_local_gb_used\n"
    fi
  fi
}

function os-hypervisor-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: hypervisor-list or 'hypervisorname' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    #hypervisors
    hv_result=$(openstack hypervisor list --sort Hypervisor --long)
    hv_all=$(echo "$hv_result")
    hv_up=$(echo "$hv_result" | grep -w 'up')
    hv_down=$(echo "$hv_result" | grep -w 'down')
    host_all=$(openstack host list)
    hv_all_aantal=$(openstack hypervisor list --sort Hypervisor --long -f value | wc -l)
    hv_up_aantal=$(echo "$hv_result" | grep -w 'up' | wc -l)
    hv_down_aantal=$(echo "$hv_result" | grep -w 'down' | wc -l)
    host_all_aantal=$(openstack host list -f value | wc -l)
    printf $yellow"List hypervisors\n"
    printf "$purple hv-all\t:"$hv_all"\n"
    printf "$green hv-up\t:"$hv_up"\n"
    printf "$red hv-down\t:"$hv_down"\n"
    printf $white"hosts\t:"$host_all"\n"
    printf $yellow"Amount hypervisors\n"
    printf "$purple hv-all\t:"$hv_all_aantal"\n"
    printf "$green hv-up\t:"$hv_up_aantal"\n"
    printf "$red hv-down\t:"$hv_down_aantal"\n"
    printf $white"hosts\t:"$host_all_aantal"\n"
  else
    for hypervisor in "$@"; do
      echo "List hypervisors: $hypervisor"
      openstack hypervisor list -f table | grep -i $hypervisor
      openstack host list -f table | grep -i $hypervisor
    done
  fi
}
