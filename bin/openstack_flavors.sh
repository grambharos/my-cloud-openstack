#!/usr/bin/env bash

#####################################################################
# script openstack_rc - flavors                                     #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#FLAVOR=============================================================================================================#

function os-flavor-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 or 'all' or 'flavorid' or 'flavorname' or 'public' or 'private' or 'shared' %s\n"
  else
    # if [[ "$1" == "all" ]]; then
      printf "Search this project for all flavors.\n"
      openstack flavor list --all --sort name
    if [[ "$1" == "public" ]]; then
      printf "Search for public flavors.\n"
      openstack flavor list --sort name --public
    elif [[ "$1" == "private" ]]; then
      printf "Search for private flavors.\n"
      openstack flavor list --sort name --private
    elif [[ "$1" == "shared" ]]; then
      printf "Search for shared flavors.\n"
      openstack flavor list --sort name --shared
    else
      printf "Search for flavor: '$1' %s\n"
      openstack flavor list | grep -i "$1"
    fi
  fi
}

function os-flavor-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'flavorid' %s\n"
  else
    printf "show flavor: $1 %s\n"
    openstack flavor show "$1"
  fi
}