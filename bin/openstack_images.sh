#!/usr/bin/env bash

#####################################################################
# script openstack_rc - images                                        #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#call the rc script
load_rc="$MYOPENSTACK_BIN/openstack_rc.sh"
. "$load_rc"

#IMAGE=============================================================================================================#

#image-show
function os-image-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: image-show 'imageid' or 'imagename' %s\n"
  else
    image_details=$(openstack image show -f json $1 | grep -w 'id\|name\|owner\|created_at\|visibility\|size\|status' | tr '",' ' ' | column -t | sort)
    if [ -z "$image_details" ]; then
      # nothing to say
      echo "empty"
    else
      printf "$green Image details\n"
      printf "$image_details\n\n"
      printf "$green Project Owner details\n"
      get_project_id=$(echo "$image_details" | awk 'NR == 4 {print $3}')
      project_owner=$(openstack project show -f json $get_project_id | grep -w 'id\|name' | tr '",' ' ' | column -t | sort)
      printf "$project_owner %s\n"
    fi
  fi
}

function os-image-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: image-list 'project' 'image' or 'public' or 'private' or 'community' or 'shared' or inactive or 'imageid' or 'imagename' %s\n"
  else
    if [[ ($1 == "image-id") || ($1 == "image-name") ]]; then
      printf "Search for image: $1 %s\n"
      openstack image list | grep -i "$1"
    elif [[ $1 == "public" ]]; then
      printf "Search for public images.\n"
      openstack image list --sort name --public
    elif [[ $1 == "private" ]]; then
      printf "Search for private images.\n"
      openstack image list --sort name --private
    elif [[ $1 == "community" ]]; then
      printf "Search for community images.\n"
      openstack image list --sort name --community
    elif [[ $1 == "shared" ]]; then
      printf "Search for shared images.\n"
      openstack image list --sort name --shared
    elif [[ $1 == "inactive" ]]; then
      printf "Search for inactive images.\n"
      openstack image list --sort name | grep -v active
    elif [[ $1 == "snapshot" ]]; then
      printf "Search for snapshots.\n"
      openstack image list --property image_type=snapshot
    else
      printf "Search current project for images\n"
      openstack image list --sort name
    fi
  fi
}

function os-project-image-list() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: project-image-list 'project-id' or 'project-name' %s\n"
  else
    #check if project-id
    if [[ $1 =~ ^[0-9a-zA-Z]+$ ]]; then
      project_image_list=$(openstack image list --long -c ID -c Name -c Size -c Status -c Protected -c Project -f value | grep $1 | tr ' ' '\t')
      printf "$purple List images project owner: $1 %s\n"
      printf $green$project_image_list
    # check if projectname
    elif [[ $1 =~ [^a-zA-Z] ]]; then
      projectid=$(openstack project list --long -c Name -c ID -f value | grep $1 | awk '{print $1}')
      project_image_list=$(openstack image list --long -c ID -c Name -c Size -c Status -c Protected -c Project -f value | grep $projectid | tr ' ' '\t')
      printf "$purple List images project owner: $1 %s\n"
      printf "$green $project_image_list"
    else
      echo "project does not exist"
    fi
  fi
}

#image-delete
function os-image-delete() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: image-delete 'imageid' or 'imagename' %s\n"
  else
    #image details
    check_image=$(image-show "$1")
    echo "$check_image\n"
    if [[ -z $check_image ]]; then
      printf "image does not exist"
      printf "empty"
    else
      read "response?Are you sure you want to delete this image? [y/N]?"
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # we remove protection from the image
        openstack image set --unprotected $1
        # we delete the image
        openstack image delete $1
        printf "$red Image $1 has been deleted\n"
      else
        printf "$red Image delete canceled\n"
      fi
    fi
  fi
}

#image-download filename id_image_you want to download
function os-image-download() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: image-download 'image-id' or 'image-name' %s\n"
  else
    #image details
    check_image=$(image-show "$1")
    echo "$check_image\n"
    if [[ -z $check_image ]]; then
      printf "image does not exist"
    else
      get_image_name=$(echo "$check_image" | awk 'NR == 4 {print $3}')
      glance image-download --progress --file $get_image_name.qcow2 $1
      # glance image-download --progress --file $get_image_name.raw $1
    fi
  fi
}
#image-upload
function os-image-upload() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: image-upload 'image-name' 'filename.qcow2' %s\n"
  else
    check_file=$2
    if test -f "$check_file"; then
      printf $yellow"OK - Image $check_file exists.\n Image upload in progress"
      glance image-create --name "$1" --disk-format qcow2 --container-format bare --file "$2" --progress
      #PID wait to finish
      lsof -p $pid +r 1 &>/dev/null
      exit_status=$?
      if [ $exit_status -gt 1 ]; then
        printf "$red CRITICAL - Error Image upload"
        exit 1
      else
        printf "$green OK - Image upload succesful"
        check_image=$(image-show "$1")
        echo "$check_image\n"
        if [[ -z $check_image ]]; then
          printf "image does not exist"
        else
          get_image_id=$(echo "$check_image" | awk 'NR == 3 {print $3}')
          echo $get_image_id
          # only v1 glance glance image-update --purge-props $get_image_id
          # openstack image set --public $get_image_id
          openstack image set --shared $get_image_id
        fi
      fi
    else
      echo "ERROR - $check_file does not exists."
    fi
  fi
}
