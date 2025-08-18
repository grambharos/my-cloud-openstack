#!/usr/bin/env bash

#####################################################################
# script openstack_rc - volumes                                      #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#VOLUMES=============================================================================================================#

# volume-show
function os-volume-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'volume-id' %s\n"
  else
    openstack volume show "$1"
  fi
}

# volume-list
function os-volume-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' or 'multiple' %s\n"
  elif [ "$#" -eq 0 ]; then
    openstack volume list
  else
    for project in "$@"; do
      printf "List: $project"
      openstack volume list | grep -i "$project"
    done
  fi
}

# volume-create
function os-volume-create() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'volume-name' 'volume-size' %s\n"
  else
    openstack volume create --size $2 $1
    printf "$green volume created"
  fi
}

# volume-delete
function os-volume-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'volume-id' %s\n"
  else
    openstack volume delete "$1"
    printf "$red volume deleted"
  fi
}

# volume-detach
function os-volume-detach() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'volume-id' %s\n"
  else
    nova volume-detach $1 $2
    os-volume-list
    printf "$green volume detached"
  fi
}

function os-volume-detach-stuck() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'volume-id' %s\n"
  else
    cinder reset-state --state detaching --attach-status detached $1
    printf "$green volume detached"
    os-volume-list
  fi
}

function os-volume-attach() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'instance-id' 'volume-id' %s\n"
  else
    nova volume-attach $1 $2 auto
    printf "$green volume attached"
    os-volume-list
  fi
}

function os-volume-backup() {
  if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'volume-name' 'volume-backup-name' %s\n"
  else
    echo "check volume: $1"
    openstack volume show $1
    read "response?Are you sure you want to edit this dev-project? [y/N]?"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      # openstack volume backup create --name <backupname> <volume_name>
      # openstack volume backup create --volume $2 $1
      # Service cinder-backup could not be found.
      openstack volume snapshot create --volume $1 --force snapshot-$2 &
      pid=$!
      wait $pid
      openstack volume create --snapshot snapshot-$2 $2
      printf "$green volume backup created"
    else
      printf "$red volume backup not created"
    fi
  fi
}
