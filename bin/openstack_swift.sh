#!/usr/bin/env bash

#####################################################################
# script openstack_rc - hypervisors                                 #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#1.SWIFT ===========================================================================================================#

function os-swift-list() {
    if [[ ("$#" -lt 0) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift list%s\n"
        swift list --lh
    fi
}

function os-swift-show-stat() {
    if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift show %s\n"
        swift stat "$1"
    fi
}

function os-swift-delete() {
    if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift delete %s\n"
        swift delete "$1"
    fi
}

function os-swift-download() {
    if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift download %s\n"
        swift download "$1"
    fi
}



# swift container ===========================================================================================================#


function os-swift-container-list() {
    if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift show %s\n"
        swift list --lh "$1"
    fi
}

function os-swift-container-upload() {
    if [[ ("$#" -lt 2) || ("$1" == "--help") || ("$1" == "-h") ]]; then
        printf "$blue Usage: $0 %s\n"
    else
        printf $yellow"swift upload %s\n"
        swift upload "$1" "$2"
        # swift upload mycontainer myfile.txt
    fi
}


# swift object ===========================================================================================================#

