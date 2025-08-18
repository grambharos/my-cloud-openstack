#!/usr/bin/env bash
if ! [ "$#" -ge 1 ]; then
  echo "Please enter UUID to migrate"
  exit 1
fi
echo "migrating server with ID $1"
JSON_STATE=`openstack server show $1 -f json`
declare -A PROPERTIES
OIFS=$IFS
IFS=','
for PROP in `jq -r .properties <<< ${JSON_STATE} | sed -e s/[\'' ']//g`
do
  IFS='='
  read -r KEY VALUE <<<${PROP}
  PROPERTIES["${KEY}"]="${VALUE}"
done
IFS=$OIFS
#STATE=`openstack server show -f value -c status $1`
if ! [ $? -eq 0 ]; then
  echo "server $1 not found or another error"
  exit 1
fi
STATE=`jq -r .status <<< ${JSON_STATE}`
if [ -z ${PROPERTIES['migrate']} ]
then
  echo "no migrate flag set for $1 not doing anything"
#  exit 1
else
  if [ ${PROPERTIES['migrate']} != 'yes' ]
  then
    echo "migrate flag set to ${PROPERTIES['migrate']} not migrating"
    exit 1
  fi
fi
case "${STATE}" in
  ACTIVE)
  if ! [ "$2" = "shutdown" ]; then
     echo "server $1 is in active state please provide shutdown as second argument to shut it down"
     exit 1
  fi
  echo "stopping server with ID $1"
  openstack server stop $1
  for i in {1..5}; do
     sleep 30
     STATE=`openstack server show -f value -c status $1`
     if [ "${STATE}" = "SHUTOFF" ]; then
        break
     fi
     printf "."
   done
   if [ "${STATE}" != "SHUTOFF" ]; then
     echo "failed to shutdown $1";
     exit 1
   fi
  ;;
  SHUTOFF)
  echo "$1 in Shutdown go ahaed"
  ;;
  VERIFY_RESIZE)
  echo "$1 already resized verifying it"
  openstack server resize confirm $1
  exit 0
  ;;
  *)
  echo "Server $1 in state ${STATE} abort"
  exit 1
  ;;
esac
echo "$1 is down migrating";
openstack server migrate $1
for i in {1..60}; do
  sleep 30
  STATE=`openstack server show -f value -c status $1`
  if [ "${STATE}" != "VERIFY_RESIZE" ]; then
     printf "."
  else
    echo "resize complete"
    break
  fi
done
if [ "${STATE}" != "VERIFY_RESIZE" ]; then
  echo "failed to migrate $1 within 30 minutes"
  exit 1
fi
echo "confirming resize"
openstack server resize confirm $1
for i in {1..5}; do
  sleep 30
  STATE=`openstack server show -f value -c status $1`
  if [ "${STATE}" != "SHUTOFF" ]; then
     printf "."
  else
    echo "resize complete starting it"
    openstack server start $1
    sleep 30
    STATE=`openstack server show -f value -c status $1`
    echo "State of $1 is now ${STATE}"
    break
  fi
done