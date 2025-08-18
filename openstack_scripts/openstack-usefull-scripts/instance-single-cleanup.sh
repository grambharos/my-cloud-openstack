#!/bin/bash
#
# Cleanup a single instance in OpenStack
# Argument:
#	instance uuid to remove
#
# Current actions:
#   if instance in a bad state:
#     Attempt cleanup with OpenStack commands (cinder & nova)
#       reset instance, attempt to detach cinder volumes, attempt to delete
#
# Author: Steven Nemetz
# snemetz@hotmail.com

# TODO:
#	script to verify resources and OpenStack DB are in sync. Report on differences
#	  On Hypervisor: instances, nwfilter, nat, ip
#	Cleanup all other references in DB: floating_ip, detach volumes, ...
#	If CLI cleanup fails, do DB and resource cleanup

tmpdir='/tmp'
Nova_Issues_File="${tmpdir}/issues-nova-instances"
log_error="instance-cleanup-errors"
error_pattern='ERROR|BUILD|building|DELETED|deleting|NOSTATE'
MYSQL_HOST='172.22.192.2'
MYSQL_USER='nova'
MYSQL_PASSWORD='CHANGE_ME'
MYSQL_CINDER_USER='cinder'
MYSQL_CINDER_PASSWORD='CHANGE_ME'
MYSQL_NOVA_USER='nova'
MYSQL_NOVA_PASSWORD='CHANGE_ME'
backend_storage='iscsi'
backend_hypervisor='libvirt'
script_volume_delete="${tmpdir}/local-volume-delete.sh"

db_validate_uuid () {
  UUID=$1
  Q=`cat <<EOF
select * from nova.instances WHERE instances.uuid = '$UUID';
EOF`
  RQ=`mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD --batch --skip-column-names -e "$Q" 2>/dev/null`
  echo "$RQ" | grep -q $UUID
  if [ $? -ne 0 ]; then
    return 1
  else
    return 0
  fi
}

mysql_call () {
  local MySQL_Host=$1
  local MySQL_User=$2
  local MySQL_Password=$3
  local SQL=$4
  local MySQL_Verbose=$5
  local SQL_Results

  echo -e "\tApplying SQL for $MySQL_User..." 1>&2
  #echo -e "\tSQL:$SQL" 1>&2
  verbose=''
  if [ -n "$MySQL_Verbose" ]; then
    verbose='--verbose --verbose'
  fi
  #echo -e "\tVerbose='$verbose'" 1>&2
  SQL_Results=$(mysql -h $MySQL_Host -u $MySQL_User -p$MySQL_Password $verbose --batch --skip-column-names -e "$SQL" 2>/dev/null)
  #SQL_Results=$(mysql -h $MySQL_Host -u $MySQL_User -p$MySQL_Password $verbose --batch --skip-column-names -e "$SQL")
  echo "$SQL_Results"
}

mysql_query () {
  local MySQL_Host=$1
  local MySQL_User=$2
  local MySQL_Password=$3
  local SQL=$4
  local SQL_Results

  #echo -e "\tApplying SQL for $MySQL_User..."
    # Add --verbose --verbose then test output for 'Rows matched: # Changed: # Warnings: #'
    # Should return: Matched 1|0 Changed 1|0(if matched was 0) Warnings 0
    # Expect 1 1 0
  #SQL_Results=$(mysql -h $MySQL_Host -u $MySQL_User -p$MySQL_Password --verbose --verbose --batch --skip-column-names -e "$SQL" 2>/dev/null)

  SQL_Results=$(mysql_call $MySQL_Host $MySQL_User $MySQL_Password "$SQL" 'Metrics' )
  Result_Stats=($(echo "$SQL_Results" | grep 'Rows matched:' | awk -F: '{ print $2$3$4 }' | awk '{ print $1" "$3" "$5 }'))
  #echo -e "\tSQL Results= ${Result_Stats[*]}"
  # if [ "${Result_Stats[@]:0:2}" == "1 1" ]; then # All Good - DOESN'T WORK, complains about too many arguments
  if [ ${Result_Stats[0]} -eq 1 -a ${Result_Stats[1]} -eq 0 ]; then
    echo -e "\tWARNING: DB query matched but didn't change anything"
    return 1
  elif [ ${Result_Stats[0]} -eq 0 ]; then
    echo -e "\tWARNING: DB query didn't match anything"
    return 2
  fi
  if [ ${Result_Stats[2]} -ne 0 ]; then
    echo -e "\tWARNING MySQL: $SQL_Results"
    return 3
  fi
  return 0
}

fixed_ip_disassociate () {
  #select * from fixed_ips where id =1;
  #+---------------------+------------+------------+----+--------------+------------+-----------+--------+----------+----------------------+------+---------------+---------+
  #| created_at          | updated_at          | deleted_at | id  | address       | network_id | allocated | leased | reserved | virtual_interface_id | host     | instance_uuid | deleted |
  #+---------------------+------------+------------+----+--------------+------------+-----------+--------+----------+----------------------+------+---------------+---------+
  #| 2015-02-12 14:50:54 | NULL                | NULL       |   1 |  192.168.64.0 |          1 |         0 |      0 |        1 |                 NULL | NULL     | NULL          |       0 |
  #| 2015-02-12 14:50:54 | 2015-02-12 19:45:57 | NULL       |  10 |  192.168.64.9 |          1 |         0 |      0 |        0 |                 NULL | node-354 | NULL          |       0 |
  #| 2015-02-12 14:50:54 | 2015-04-03 03:22:12 | NULL       | 100 | 192.168.64.99 |          1 |         1 |      0 |        0 |               211369 | NULL     | 4421818a-ad37-49ea-b917-6598c0bd29f5 |       0 |

  local Instance_UUID=$1
  local Fixed_IP=$2
  local Host=$3
  local VM_Name=$4
  # For each fixed IP clean all floating IPs attached to it

  echo -e "\n\tAttempting to remove Fixed IP: $Fixed_IP..."
  nova remove-fixed-ip $Instance_UUID $Fixed_IP
  error=$?
  if [ $error -ne 0 ]; then
    echo -e "\t\tERROR: $error: Fixed IP: $Fixed_IP, Instance: $Instance_UUID failed to remove fixed ip"
    # Cleanup database
    # update nova.fixed_ips set updated_at=now(),allocated=1,host=NULL,instance_uuid=NULL,virtual_interface_id=NULL where address = "$Fixed_IP";
    # Cleanup hypervisor - remove ip and nwfilter
    # ssh root@$Host
  fi
}

floating_ip_disassociate () {
  #select * from nova.floating_ips where id =4383;
  #+---------------------+------------+------------+------+-------------+-------------+------------+------+---------------+------+-----------+---------+
  #| created_at          | updated_at          | deleted_at | id   | address     | fixed_ip_id | project_id                       | host     | auto_assigned | pool | interface | deleted |
  #+---------------------+------------+------------+------+-------------+-------------+------------+------+---------------+------+-----------+---------+
  #| 2015-02-12 15:08:21 | NULL                | NULL       | 4383 | 172.22.84.6 |        NULL | NULL                             | NULL     |             0 | nova | eth2.519  |       0 |
  #| 2015-02-12 15:03:11 | 2015-03-25 00:30:12 | NULL       |    1 | 172.22.67.1 |        4365 | ba5aee7d599245c981c3b0ffc518d532 | node-277 |             1 | nova | eth2.519  |       0 |

  local Instance_UUID=$1
  local Floating_IP=$2
  local Host=$3
  echo -e "\n\tAtttempting to remove Floating IP: $Floating_IP..."
  nova floating-ip-disassociate $Instance_UUID $Floating_IP
  error=$?
  if [ $error -ne 0 ]; then
    echo -e "\t\tERROR: $error: Floating IP: $Floating_IP, Instance: $Instance_UUID failed to disassociate floating ip"
    # Cleanup database
    # update nova.floating_ips set updated_at=now(),fixed_ip_id=NULL,project_id=NULL,host=NULL,auto_assigned=0 where address = "$Floating_IP";
    # Cleanup hypervisor - remove IP and NAT
    # ssh root@$Host
  fi
}

ip_cleanup () {
  local Instance_UUID=$1
  local VM_Name=$2
  local Host=$3
  declare -a fixed_ips
  declare -a floating_ips

  script_ip_cleanup="${dirtmp}/host_ip_clean.sh"

  echo -e "\tCleaning IPs..."
  # Query DB to get all fixed IPs IDs
  SQL_Fixed_Ips="select id from nova.fixed_ips where instance_uuid = '$Instance_UUID';"
  fixed_ip_ids=$(mysql_call $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Fixed_Ips")
  for fixed_id in $fixed_ip_ids; do
    echo -e "\tCleaning Fixed Ip ID: $fixed_id"
    # Query DB for floating IP IDs
    SQL_Floating_Ips="select id from nova.floating_ips where fixed_ip_id = '$fixed_id';"
    floating_ip_ids=$(mysql_call $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Floating_Ips")
    for floating_id in $floating_ip_ids; do
      echo -e "\t\tCleaning Floating IP ID: $floating_id"
      # Get Floating IPs
      SQL_Floating_IP="select address from nova.floating_ips where id = '$floating_id';"
         	#floating_ips=("${floating_ips[@]}" $(mysql_call))
      floating_ips+=($(mysql_call $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Floating_IP"))
      # Clean floating IP in database
      SQL_Floating_Clean="update nova.floating_ips set updated_at=now(),fixed_ip_id=NULL,project_id=NULL,host=NULL,auto_assigned=0 where id = '$floating_id';"
      mysql_query $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Floating_Clean"
    done
    # Clean fixed IP - maintan table to clean host later
    #fixed_ips+=($(mysql_call))
    SQL_Fixed_IP="select address from nova.fixed_ips where id = '$fixed_id';"
    fixed_ips+=($(mysql_call $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Fixed_IP"))
    SQL_Fixed_Clean="update nova.fixed_ips set updated_at=now(),allocated=1,host=NULL,instance_uuid=NULL,virtual_interface_id=NULL where id = '$fixed_id';"
    mysql_query $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Fixed_Clean"
  done
  if [ -n "${fixed_ips[*]}" -o -n "${floating_ips[*]}" ]; then
    echo -e "\nHost IP cleanup..."
    echo "Clean '$VM_Name' on '$Host'"
    echo "Floating IPs: ${floating_ips[*]}"
    echo "Fixed IPs: ${fixed_ips[*]}"
      # /var/lib/nova/instances/ gone
      # vm gone
      # NAT exists
      # /etc/libvirt/nwfilter/ gone
      # /etc/libvirt/qemu/ gone
      # fixed IP gone

    cat > $script_ip_cleanup <<SCRIPT
#!/bin/bash
# OpenStack repair cleanup
#   Cleanup floating & fixed ips for:
#     Host: $Host
#     Instance UUID: $Instance_UUID
#     VM Name: $VM_Name
#     Floating IPs: ${floating_ips[*]}"
#     Fixed IPs: ${fixed_ips[*]}

# Floating: remove NAT & IP
for float_ip in ${floating_ips[*]}; do
  iptables -S -t nat | grep \$float_ip | sed 's/^-A/-D/' | xargs -r -L1 iptables --table nat
  if [ \$(ip addr | grep \$float_ip | wc -l) -ne 0 ]; then
    ip addr del \${float_ip}/32 dev eth2.519
  fi
done
# Fixed: remove nwfilter & IP
#	Might not be needed - appears that removing VM takes care of
# - virsh dumpxml $VM_Name | grep filterref | ... | xargs -n1 virsh nwfilter-undefine
SCRIPT

    scp $script_ip_cleanup root@$Host:/tmp/$(basename $script_ip_cleanup)
    ssh root@$Host "bash /tmp/$(basename $script_ip_cleanup)"
  fi
}

volume_delete () {
  local Volume_UUID=$1

  echo -e "\n\tAttempting to deleted volume: $Volume_UUID"
  #cinder delete $Volume_UUID
  #cinder reset-state --state available $Volume_UUID
  cinder force-delete $Volume_UUID
  error=$?
  if [ $error -eq 0 ]; then
    #Verify it is deleted
    status=$(nova volume-show $Volume_UUID | grep ' status ' | awk '{ print $4 }')
    if [ -n "$status" ]; then
      echo -e "\tVolume delete accepted but not sucessful. Status: $status"
      #error=1
    fi
  fi
  if [ $error -ne 0 ]; then
    echo -e "\t\tERROR: $error: Volume: $Volume_UUID failed to delete"
    ### Cleanup database
    # TODO: clean database, cleanup resources on storage node (iscsi, files, ...)
    #cinder.volumes iscsi_targets reservations volume_metadata
    #volumes: updated_at, deleted_at, host, instance_uuid, ...
    #iscsi_targets: updated_at, deleted_at, deleted, host, volume_id
    #reservations: updated_at, deleted_at, deleted, uuid
    #volume_metadata: updated_at, deleted_at, deleted, volume_id
    # update nova.block_device_mapping set updated_at=now(),deleted_at=now(),deleted=id where not deleted and volume_id='$Volume_UUID';
    # mysql -e "update cinder.volumes set updated_at=now(),deleted_at=now(),terminated_at=now(),mountpoint=NULL,instance_uuid=NULL,status='deleted',deleted=1 where deleted=0 and id='$Volume_UUID';"
    return
    echo "HELP: show never be here"
    exit
    case $backend_storage in
      iscsi)
        ### Cleanup storage node - iscsi
        echo -e "\tISCSI Clenaup..."
        host=$(cinder show $Volume_UUID | grep os-vol-host-attr:host | awk '{ print $4 }' | cut -d\# -f1)
        #   ssh to the volume hosting storage
        #TEST is in error_deleting:  node-230 - 9d4253af-e0ef-4c31-a955-72283f9aa20b
        # Create script
        cat >$script_volume_delete <<EOF
#!/bin/bash

# identify the target lun
target_lun=\$(tgt-admin -s | grep $Volume_UUID | grep ^Target | awk '{ print \$2 }' | cut -d: -f1)
# Backing device: /dev/cinder/volume-<UUID>
backing_store_path=\$(tgt-admin -s | grep $Volume_UUID | grep 'Backing store path' | awk '{ print \$4 }')

# mark the target offline - offline target
tgt-admin --offline tid=\$target_lun

# get a list of all active connections to this lun (If there are none, skip the next step)
for session_id in \$(tgtadm --lld iscsi --op show --mode conn --tid \$target_lun | grep ^Session | awk '{ print \$2 }'); do
  # close active sessions - didn't close
  tgtadm --lld iscsi --op delete --mode conn --tid \$target_lun --sid \$session_id
  # Might need --cid \$connection_id
done

# delete the lun - got error: target is still active - Can add --force
tgtadm --lld iscsi --op delete --mode target --tid \$target_lun

# delete the target file in /var/lib/cinder/volumes
# How to determine this path?
rm /var/lib/cinder/volumes/volume-$Volume_UUID

# delete the logical volume
lvremove -f cinder/volume-$Volume_UUID

# - Please note the above will leave a stale connection reference in the local iscsi connection table.  The connection itself is gone, however.  This doesn't cause any problems and can be corrected by running the following:
#    # iscsiadm -m node -T <target name> -p <cinder host>:<port> -u
#    # iscsiadm -m node -T <target name> -p localhost:3260 -u
EOF
        #scp $script_volume_delete root@$host:
        # run script
        #ssh root@$host bash ./$(basename $script_volume_delete)
      ;;
      *)
        echo "ERROR: Unsupported storage backend: $backend_storage"
      ;;
    esac
  fi
}

volume_detach () {
  local Instance_UUID=$1
  local Volume_UUID=$2
  
  # This might not be complete
  # For these conditions - good enough that can delete instance afterwards
  # | ERROR   | -          | Running     |
  # | ERROR   | -          | NOSTATE     |
  # For these conditions - instance delete still fails on detach afterwards
  # | ACTIVE  | -          | deleting    |

  echo -e "\n\tDetaching: $Volume_UUID"
  SQL_Cinder=$(cat <<SQL_SCRIPT
update cinder.volumes set updated_at=now(),attach_status='detached',attached_host=NULL,status='available' where id ='$Volume_UUID' and not attach_status='detached';
SQL_SCRIPT
)
  SQL_Nova=$(cat <<SQL_SCRIPT
update nova.block_device_mapping set deleted_at=now(),updated_at=now(),deleted=id where not deleted and volume_id='$Volume_UUID';
SQL_SCRIPT
)
  # Other nova tables: volumes (empty), 
  # Query afterwards to verify success?
      #if [ "$(nova volume-show $V 2>/dev/null | grep '| status ' | awk '{ print $4 }')" != 'in-use' ]; then
  nova volume-detach $Instance_UUID $Volume_UUID
  error=$?
  if [ $error -ne 0 ]; then
    echo -e "\t\tERROR: $error: Instance: $Instance_UUID Volume: $Volume_UUID while attempting detach"
    # echo "SQL Nova: $Q"
    # Add --verbose --verbose then test output for 'Rows matched: # Changed: # Warnings: #'
    # Should return: Matched 1|0 Changed 1|0(if matched was 0) Warnings 0
    # Expect 1 1 0
    #RQ=$(mysql -h $MYSQL_HOST -u $MYSQL_NOVA_USER -p$MYSQL_NOVA_PASSWORD --batch --skip-column-names -e "$SQL_Nova")
    mysql_query $MYSQL_HOST $MYSQL_NOVA_USER $MYSQL_NOVA_PASSWORD "$SQL_Nova"
    #if [ $? -eq 0 ]; then
    #  return $?
    # echo "RQ: $RQ"
    # echo "SQL Cinder: $Q"
    #RQ=$(mysql -h $MYSQL_HOST -u $MYSQL_CINDER_USER -p$MYSQL_CINDER_PASSWORD --batch --skip-column-names -e "$SQL_Cinder")
    mysql_query $MYSQL_HOST $MYSQL_CINDER_USER $MYSQL_CINDER_PASSWORD "$SQL_Cinder"
    # echo "RQ: $RQ"
    return 0
  else
    return 0
  fi
}

instance_delete () {
  local Instance_UUID=$1
  local host=$2

  echo -e "\n\tAttempting to deleted instance: $Instance_UUID..."
  nova reset-state --active $Instance_UUID
  nova force-delete $Instance_UUID
  error=$?
  if [ $error -ne 0 ]; then
    echo -e "\t\tERROR: $error: Instance: $Instance_UUID while attempting delete"
    ### Cleanup database
    # mysql -e "update nova.instances set updated_at=now(),deleted_at=now(),terminated_at=now(),vm_state='deleted',task_state=NULL,deleted='1' where uuid='$Instance_UUID';"
    ### Cleanup hypervisor - libvirt (kvm)
    # - ssh to the hosting hypervisor
    # - destroy the instance
    # - get the instance id from libvirt.xml
    # vm_domain=$(grep "<name>instance" /var/lib/nova/instances/${Instance_UUID}/libvirt.xml)
    # - destroy and undefine the instance
    #    # virsh destroy instance-XXXXXXXX
    #    # virsh undefine instance-XXXXXXXX
    # - delete the instance directory
    #    # rm -rf /var/lib/nova/instances/${Instance_UUID}
  fi
}

instance_cleanup () {
  local Instance_UUID=$1
  local error error2

  echo "Attempting to fix: $Instance_UUID"
  details=$(nova show $Instance_UUID 2>/dev/null)
  if [ $? -eq 0 ]; then
      #  # will fail if task_state=deleting
      #  ACTIVE,deleting,NOSTATE - Still trying
      #  ERROR,-,NOSTATE - reset,force
      #  'fault' may contain a stack trace
    # Reset instance API
    nova reset-state --active $Instance_UUID
    # Delete instance API
    nova force-delete $Instance_UUID
    error=$?
    sleep 4
    nova show $Instance_UUID >/dev/null 2>&1
    error2=$?
    if [ $error -ne 0 -o $error2 -eq 0 ]; then
      # If instance still exists
      echo -e "\tForce Delete failed. Starting deep delete..."
      # Reset instance API
      nova reset-state --active $Instance_UUID
      ###  Get attached volumes and detach, then delete
        #IName=$(echo "$details" | grep '| name ' | awk '{ print $4 }')
        # Change to get data from $details
        #volumes=$(nova list --name $IName --fields os-extended-volumes:volumes_attached | egrep -v '[+]|ID' | awk -F\| '{ print $3 }' | sed "s/u\'/\'/g" | sed s/\'/\"/g | jq '.[].id?' | sed s/\"//g)
      volumes=$(echo "$details" | grep 'os-extended-volumes:volumes_attached' | awk -F\| '{ print $3 }' | jq '.[].id' | sed s/\"//g)
      for V in $volumes; do
        volume_detach $Instance_UUID $V
        if [ $? -eq 0 ]; then
          volume_delete $V
        fi
      done
      # Attempt to delete instance again
      nova reset-state --active $Instance_UUID
      nova force-delete $Instance_UUID
      error3=$?
      sleep 4
      nova show $Instance_UUID >/dev/null 2>&1
      error4=$?
      if [ $error3 -ne 0 -o $error4 -eq 0 ]; then
        # If still failing clean IPs
        Host=$(echo "$details" | grep OS-EXT-SRV-ATTR:host | awk '{ print $4 }')
        Instance_Name=$(echo "$details" | grep OS-EXT-SRV-ATTR:instance_name | awk '{ print $4 }')
        ip_cleanup $Instance_UUID $Instance_Name $Host
        ### Get Floating IPs and disassociate
        #Floating_IP=$(echo "$details" | grep network | awk '{ print $6 }')
        #floating_ip_disassociate $Instance_UUID $Floating_IP
        ### Get Fixed IPs and remove
        #Fixed_IP=$(echo "$details" | grep network | awk '{ print $5 }' | sed 's/,$//')
        # nova fixed-ip-get to get/verify fixed ip - returns: instance name, host
        #fixed_ip_disassociate $Instance_UUID $Fixed_IP
        sleep 2
        instance_delete $Instance_UUID $Host
      fi
    #else
      # verify instance is gone, otherwise call instance_delete
    fi
  else
    echo "ERROR: $?: Instance $Instance_UUID not found"
  fi
}

Instance_UUID=$1

cp /dev/null $log_error
echo "Starting instance error cleanup via CLI..."
nova reset-state --active $Instance_UUID
instance_cleanup $Instance_UUID
