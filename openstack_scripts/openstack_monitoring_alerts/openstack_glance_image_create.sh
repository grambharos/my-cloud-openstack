#/bin/bash

#
# Script restores snapshot created in OpenStack
# Script created by Lex IT, Alex Flora
# usage: snapshot-restore.sh <snapshot image name> <server name to restore to>
# to use: make sure to install the following python openstack modules: 
# pip install python-openstackclient python-keystoneclient python-glanceclient python-novaclient python-neutronclient
#


#
# Query needed variables
#

if [ "$#" -eq  "0" ]
    then
        echo -e "usage: restore_snapshot <name of snapshot> <name of server>"
        echo -e "Querying available snapshots, one moment please ..."
        glance image-list

        echo -e "\n\033[0;33mGive name of snapshot to restore"
        echo -e "\033[0m"
        read SNAPSHOT

        echo -e "\n\033[0;33mGive server name to restore"
        echo -e "\033[0m"
        read SERVER
    else
        SNAPSHOT=$1
        SERVER=$2
fi

echo -e "\n\033[0mQuery needed server information from server $SERVER, one moment please ..."
NETWORK=$(nova show IWF039 | awk '/network/ {print $2}' | sed -e 's/^[[:space:]]*//')
ZONE=$(nova show IWF039 | awk '/OS-EXT-AZ:availability_zone/ {print $4}' | sed -e 's/^[[:space:]]*//')
FLAVOR=$(nova show IWF039 | awk '/flavor:original_name/ {print $4}' | sed -e 's/^[[:space:]]*//')
SERVERID=$(nova show IWF039 | awk -F '|' '/\<id\>/ {print $3; exit}' | sed -e 's/^[[:space:]]*//')
NETWORKPORT=$(nova interface-list IWF039 | awk -F '|' '/ACTIVE/ {print $3}' | sed -e 's/^[[:space:]]*//')

# Print out variables
echo -e "\033[0mnetwork: \033[0;32m$NETWORK"
echo -e "\033[0mzone: \033[0;32m$ZONE"
echo -e "\033[0mflavor: \033[0;32m$FLAVOR"
echo -e "\033[0mserver_id: \033[0;32m$SERVERID"
echo -e "\033[0mnetwork_port_id: \033[0;32m$NETWORKPORT"
echo -e "\033[0mSnapshot image: \033[0;32m$SNAPSHOT"
echo -e "\033[0mServer naam: \033[0;32m$SERVER"

# Ask confirmation
echo -e "\n\033[0mGoing to restore snapshot image $SNAPSHOT to server $SERVER"
read -p "Is this correct (y/n) ? " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Remove current instance
    echo -e "\n\033[0mRemove current instance"
    nova delete $SERVERID
    sleep 3
    # Rebuild instance from snapshot image
    echo -e "\nRebuild instance from snapshot using command:"
    echo -e "\033[0mnova boot --poll --flavor $FLAVOR --image $SNAPSHOT --security-groups default --availability-zone $ZONE --nic port-id=$NETWORKPORT $SERVER"
    nova boot --poll --flavor $FLAVOR --image $SNAPSHOT --security-groups default --availability-zone $ZONE --nic port-id=$NETWORKPORT $SERVER
fi 