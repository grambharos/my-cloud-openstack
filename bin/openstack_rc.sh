#!/usr/bin/env bash

#####################################################################
# script openstack_rc                                                #
# Author: germio.rambharos@gmail.com                                #
#####################################################################

#openrc file all regions
#colors
yellow="\033[33m"
green="\033[32m"
red="\033[31m"
green="\033[32m"
purple="\033[34m"
white="\033[37m"
purple_bold="\033[1;35m"
xblue_bold="\033[1;34m"
reset="\033[0m"

#CUSTOM
export OS_NO_CACHE=true
# export OS_AUTH_STRATEGY=keystone
#export OS_INTERFACE=publicURL
#export OS_ENDPOINT_TYPE=publicURL
#export OS_IDENTITY_PROVIDER="keycloak-idp"
#export OS_PROTOCOL="oidc"
#export OS_ACCESS_TOKEN="eyJhbGciOiJSUzI1NiIsIn..........9uFum6TWK_69OAbM3RjFbjiDvg"
#export OS_PROJECT_ID="27a7e59d391d55c6cf4ead12227da57e"
#export OS_SERVICE_TOKEN=thequickbrownfox-jumpsover-thelazydog

#API ENDPOINTS
# export OS_VOLUME_API_VERSION=2 #set cinderv2 volume ceph+ --os-volume-api-version 2
export OS_VOLUME_API_VERSION=3 #set cinderv3 volume ceph+
# export OS_AUTH_URL                         keystone
# export OS_IDENTITY_API_VERSION=2     #set keystonev2
# export OS_IDENTITY_API_VERSION=3     #set keystonev3
# export OS_IMAGE_API_VERSION=2        #set glance
# export OS_COMPUTE_API_VERSION=2      #set nova
# export OS_COMPUTE_API
# export ST_AUTH_VERSION=3             #set swift version3
# export ST_AUTH_VERSION=2.0           #set swift version2.0
# export OS_OBJECT_STORE_API_VERSION=1 #set swift
# export OS_DNS_API_VERSION=2          #set designate
# export OS_NETWORK_API_VERSION=2      #set neutron
# export OS_ _API_VERSION=2            #

# https://swift.ams1.cloud.ecg.so/v1/4db9c1b6fce44e328f5dfb61bf37710d
# export ST_AUTH=https://swift.ams1.cloud.ecg.so/v1
# export ST_USER=adm-grambharos
# export ST_KEY=$(security find-generic-password -ga "grambharos" -s ecg-ldap -w)
# export OS_STORAGE_URL=https://swift.ams1.cloud.ecg.so/v1
# export OS_AUTH_TOKEN=$TOKEN

#HASHI
# export VAULT_ADDR=https://vault.foo.net

# USER ====================================================================================================================================================================================================#

#users
# USERNAME_DEFAULT=$(echo id -n)
# LDAP_USERNAME=grambharos
# USERNAME=$LDAP_USERNAME
# USERNAME_ADM=adm-$LDAP_USERNAME
# USERNAME_ADMIN=admin
# export OS_USERNAME=$USERNAME_ADM
MY_PASSWORD=$(security find-generic-password -ga "grambharos" -s ecg-ldap -w)

# set user
# complete -W "username dev adm admin" set-user
function os-user-set() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: set-user 'username' \n"
  elif [[ "dev" == "$1" ]]; then
    export OS_USERNAME=$LDAP_USERNAME
    os-env-list
  elif [[ "normal" == "$1" ]]; then
    export OS_USERNAME=$LDAP_USERNAME
    os-env-list
  elif [[ "kleinanzeigen-automation" == "$1" ]]; then
    export OS_USERNAME=kleinanzeigen-automation
    os-env-list
  elif [[ "adm" == "$1" ]]; then
    export OS_USERNAME=adm-$LDAP_USERNAME
    os-env-list
  elif [[ "admin" == "$1" ]]; then
    export OS_USERNAME=adm-$LDAP_USERNAME
    os-env-list
  else
    export OS_USERNAME=$1
    os-env-list
  fi
}

function os-user-clear() {
  export OS_USERNAME=
  os-env-list
}

#user list
function os-user-list() {
  if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'userid' or 'username' \n"
  elif [ "$#" -eq 0 ]; then
    #all users
    user_list=$(openstack user list)
    echo $user_list
  else
    for user in "$@"; do
      user_list=$(openstack user list | grep $1)
      printf $green$user_list
    done
  fi
}

#show userid
function os-user-show() {
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'userid' or 'username' \n"
  else
    #check user
    user_list=$(openstack user list -f value | grep $1)
    echo $yellow"Found user:\n"$user_list'\n'
    #check role - user -project
    user_role_project=$(openstack role assignment list --user $1 -f value)
    echo "$green User:\t\t" "Role:\t" "Project:"
    echo $user_role_project | while read -r line; do
      user_role_id=$(echo $line | awk '{print $1}')
      user_role=$(openstack role list -f value | grep $user_role_id | awk '{print $2}')
      user_project_id=$(echo $line | awk '{print $3}')
      user_project=$(openstack project list -f value | grep $user_project_id | awk '{print $2}')
      echo $1 "\t" $user_role"\t" $user_project
    done
  fi
}

#user add to project
function os-user-role-add() {
  if [[ ("$#" -lt 3) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: user-role-add 'user' 'role' 'project' %s\n"
  else
    openstack role add --user $1 --project $3 $2
  fi
}

#user remove to project
function os-user-role-remove() {
  if [[ ("$#" -lt 3) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: user-role-remove 'user' 'project' 'role' %s\n"
  else
    openstack role remove --user $1 --project $2 $3
  fi
}

#token
function os-user-token-openstack() {
  # set -x
  mytoken=$(openstack token issue -f value | awk 'NR == 2 {print $1}')
  echo "OS_TOKEN:" $mytoken
  export OS_TOKEN=$mytoken
}

# ENV====================================================================================================================================================================================================#
function os-env-clear() {
  export OS_USERNAME=
  export OS_REGION_NAME=
  export OS_PROJECT_ID=
  export OS_PROJECT_NAME=
  export OS_TENANT_ID=
  export OS_TENANT_NAME=
  os-env-list
}
function os-env-list() {
  printf "user\t: $OS_USERNAME\n"
  printf "region\t: $OS_REGION_NAME\n"
  printf "project\t: $OS_PROJECT_NAME\t | $OS_PROJECT_ID\n"
  printf "tenant\t: $OS_TENANT_NAME\t | $OS_TENANT_ID\n"
}
#REGIONS===================================================================================================================================================================================================#
function os-region-list() {
  openstack region list
}
function region-show() {
  openstack region show $1
}
# complete -W "dev ix3-control ams1 dus2-control dus1 ams5-control ams2" set-region
function os-region-set() {
  export OS_REGION_NAME=$1
}
#PROJECTS===================================================================================================================================================================================================#

function os-project-set() {
  # echo "os-project-set" "$1"
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: $0 'project-id' or 'project-name' %s\n"
  else
    #space is set as delimiter
    IFS=''
    project_word=$1
    #show all projects containg $1
    projects_all=$(openstack project list -f value)
    other_projects=$(echo $projects_all | grep -i $1)
    printf "$purple Projects containing: $1 %s\n"
    printf $yellow$other_projects"\n\n"
    projects=$(echo $projects_all | grep -Ew "$1$")
    #if project does not exist
    if [ -z "$projects" ]; then
      printf "$red Project: $1 does not exist\n"
      printf "$red Please choose a correct project.\n"
    else
      # check how many projects contain $1
      project_rows=$(echo "$projects" | wc -l)
      # if project_rows == 1
      if [ "$project_rows" -eq 1 ]; then
        printf "$purple Project found: $1 %s\n"
        printf $green
        project_id=$(echo "$projects" | awk 'NR == 1 {print $1}')
        project_name=$(echo "$projects" | awk 'NR == 1 {print $2}')
        export OS_TENANT_ID=$project_id
        export OS_TENANT_NAME=$project_name
        export OS_PROJECT_ID=$project_id
        export OS_PROJECT_NAME=$project_name
        os-env-list
      # if project_rows > 1
      elif [ "$project_rows" -gt 1 ]; then
        printf "$red Multiple projects contain: $1 \n"
        printf "$red Please choose a correct project \n"
        printf $yellow$projects"\n"
      fi
    fi
  fi
}

#clean up env
function os-project-clear() {
  export OS_TENANT_ID=
  export OS_TENANT_NAME=
  export OS_PROJECT_ID=
  export OS_PROJECT_NAME=
}

#environment region and project
# complete -W "dev ix3-control ams1 dus2-control dus1 ams5-control ams2" set-env
function os-env() {
  # export OS_USERNAME=adm-$LDAP_USERNAME
  export OS_USERNAME=$LDAP_USERNAME
  MY_PASSWORD=$(security find-generic-password -ga $LDAP_USERNAME -s ecg-ldap -w)
  if [[ ("$#" -lt 1) || ("$1" == "--help") || ("$1" == "-h") ]]; then
    printf "$blue Usage: set-env 'region' 'project' %s\n"
  else
    if [[ "dev" == "$1" ]]; then
      #projects: dev-grambharos
      os-project-clear
      export OS_REGION_NAME=ams1
      export OS_AUTH_URL=https://keystone.ams1.cloud.ecg.so/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      os-project-set "dev-$LDAP_USERNAME"
      if [[ "terraform" == "$2" ]]; then
        cd ${CLOUD_GIT_DIR}/terraform/dev
        terraform show
        make
      fi
    # elif [[ "ix3-control" == "$1" ]]; then
    #   #horizon http://allinone-controller-0hdu.ix3-control.cloud.ecg.so/horizon/auth/login/?next=/horizon/
    #   #projects:admin, cloudteam, cloud-ams1, cloud-mgmt
    #   os-project-clear
    #   export OS_REGION_NAME=ix3-control
    #   export OS_AUTH_URL=https://keystone.ix3-control.cloud.ecg.so/v2.0
    #   export OS_USERNAME=$USERNAME
    #   export OS_PASSWORD=$MY_PASSWORD
    #   if [[ ! -z "$2" ]]; then
    #     os-project-set "$2"
    #   fi
    elif [[ "ix3-control" == "$1" ]]; then
      # https://dus2-control.cloud.ecg.so/horizon/auth/login/?next=/horizon/
      #projects:admin, cloud-dus1, cloud-mgmt
      os-project-clear
      export OS_REGION_NAME=ix3-control
      export OS_AUTH_URL=https://keystone.ix3-control.cloud.ecg.so/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
    elif [[ "ams1" == "$1" ]]; then
      #horizon https://ams1.cloud.ecg.so/auth/login/
      #projects: cloud-canary,cloud-nonprod,cloud-prod,dev-grambharos
      os-project-clear
      export OS_REGION_NAME=ams1
      export OS_AUTH_URL=https://keystone.ams1.cloud.ecg.so/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
      # er is eigenlijk geen overlay underlay in ams2
    elif [[ "ams5-control" == "$1" ]]; then
      #horizon http://allinone-controller-0hdu.ix3-control.cloud.ecg.so/horizon/auth/login/?next=/horizon/
      #projects:#cloud-ams1
      os-project-clear
      export OS_REGION_NAME=ams5-control
      # export OS_AUTH_URL=https://keystone.ams5-control.cloud.ecg.so/v2.0
      export OS_AUTH_URL=https://keystone.api.ams2.cloud/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
    elif [[ "ams2" == "$1" ]]; then
      #projects: cloud-canary, cloud-nonprod, cloud-prod
      os-project-clear
      export OS_REGION_NAME=ams2
      export OS_AUTH_URL=https://keystone.api.ams2.cloud/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
    elif [[ "dus2-control" == "$1" ]]; then
      # https://dus2-control.cloud.ecg.so/horizon/auth/login/?next=/horizon/
      #projects:admin, cloud-dus1, cloud-mgmt
      os-project-clear
      export OS_REGION_NAME=dus2-control
      export OS_AUTH_URL=https://keystone.dus2-control.cloud.ecg.so/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
    elif [[ "dus1" == "$1" ]]; then
      #horizon https://ams1.cloud.ecg.so/auth/login/
      #projects: cloud-canary,cloud-nonprod,cloud-prod
      os-project-clear
      export OS_REGION_NAME=dus1
      export OS_AUTH_URL=https://keystone.dus1.cloud.ecg.so/v2.0
      export OS_USERNAME=$LDAP_USERNAME
      export OS_PASSWORD=$MY_PASSWORD
      if [[ ! -z "$2" ]]; then
        os-project-set "$2"
      fi
    else
      printf "Region: $1 does not exist.\n"
    fi
  fi
}

# kleinanzeigen-automation
function os-env_dus1_ek-k8s-nonprod(){
  export OS_USE_KEYRING=true
  export OS_REGION_NAME=dus1
  export OS_AUTH_STRATEGY=keystone
  export OS_AUTH_URL=https://keystone.dus1.cloud.ecg.so/v2.0/
  export OS_NO_CACHE=true
  export OS_TENANT_NAME=ek-k8s-nonprod
  export OS_PROJECT_NAME=ek-k8s-nonprod
  export OS_USERNAME=kleinanzeigen-automation
  KLEINANZEIGEN_AUTOMATION_PASSWORD=$(security find-generic-password -ga "grambharos" -s kleinanzeigen-automation -w)
  export OS_PASSWORD=$KLEINANZEIGEN_AUTOMATION_PASSWORD
}

function os-env_ams2_ek-prod(){
  # export OS_USE_KEYRING=true
  export OS_REGION_NAME=ams2
  export OS_AUTH_STRATEGY=keystone
  export OS_AUTH_URL=https://keystone.ams2.cloud.ecg.so/v2.0/
  export OS_NO_CACHE=true
  export OS_TENANT_NAME=ek-prod
  export OS_PROJECT_NAME=ek-prod
  export OS_USERNAME=kleinanzeigen-automation
  export OS_PASSWORD=$KLEINANZEIGEN_AUTOMATION_PASSWORD
  # KLEINANZEIGEN_AUTOMATION_PASSWORD=$(security find-generic-password -ga "grambharos" -s kleinanzeigen-automation -w)
  # export OS_PASSWORD=$KLEINANZEIGEN_AUTOMATION_PASSWORD
}


# #cloud-ci (jenkins build)
# function os-set-env_cloud-ci() {
#   export OS_USE_KEYRING=true
#   export OS_REGION_NAME=ams1
#   export OS_AUTH_STRATEGY=keystone
#   export OS_AUTH_URL=https://keystone.ams1.cloud.ecg.so/v2.0/
#   export OS_NO_CACHE=true
#   export OS_TENANT_NAME=cloud-ci
#   export OS_USERNAME=cloud-jenkins
#   export OS_PROJECT_NAME=cloud-ci
#   CI_PASSWORD=$(security find-generic-password -ga "cloud-ci" -s ecg-ldap-ci -w)
#   export OS_PASSWORD=$CI_PASSWORD
# }

# # canary
# function os-set-env_canary-ams1(){
#   export OS_USE_KEYRING=true
#   export OS_REGION_NAME=ams1
#   export OS_AUTH_STRATEGY=keystone
#   export OS_AUTH_URL=https://keystone.ams1.cloud.ecg.so/v2.0/
#   export OS_NO_CACHE=true
#   export OS_TENANT_NAME=cloud-canary
#   export OS_PROJECT_NAME=cloud-canary
#   export OS_USERNAME=adm-$LDAP_USERNAME
#   CANARY_PASSWORD=$(security find-generic-password -ga "grambharos" -s ecg-ldap -w)
#   export OS_PASSWORD=$CANARY_PASSWORD
# }

# # canary
# function os-set-env_canary-dus1(){
#   export OS_USE_KEYRING=true
#   export OS_REGION_NAME=dus1
#   export OS_AUTH_STRATEGY=keystone
#   export OS_AUTH_URL=https://keystone.dus1.cloud.ecg.so/v2.0/
#   export OS_NO_CACHE=true
#   export OS_TENANT_NAME=cloud-canary
#   export OS_PROJECT_NAME=cloud-canary
#   export OS_USERNAME=adm-$LDAP_USERNAME
#   CANARY_PASSWORD=$(security find-generic-password -ga "grambharos" -s ecg-ldap -w)
#   export OS_PASSWORD=$CANARY_PASSWORD
# }

# # canary
# function os-set-env_canary-ams2(){
#   export OS_USE_KEYRING=true
#   export OS_INTERFACE=public
#   export OS_REGION_NAME=ams2
#   export OS_ENDPOINT_TYPE=publicURL
#   export OS_AUTH_URL=https://keystone.api.ams2.cloud/v2.0/
#   export OS_AUTH_STRATEGY=keystone
#   export OS_PROJECT_NAME=cloud-canary
#   export OS_TENANT_NAME=cloud-canary
#   export OS_USERNAME=adm-$LDAP_USERNAME
#   CANARY_PASSWORD=$(security find-generic-password -ga "grambharos" -s ecg-ldap -w)
#   export OS_PASSWORD=$CANARY_PASSWORD
# }
