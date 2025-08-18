#!/usr/bin/env bash

#####################################################################
#script to snapshot project instance                                #
#this is only for https://github.es.ecg.tools/ in your git folder  #
#Author: germio.rambharos                                        #
#####################################################################

#set-overlay-region-project
#set-dus1-project dk-ci

#check instance exist
#openstack server list | grep  -i <instance-id or instance-name>

#create instance snapshot-date
# openstack server image create --name snappy-windows2019-cli --wait cloud-win2019

#show snapshot info
#openstack image show <instance-id or instance-name>
#openstack image list --property image_type=snapshot | grep -i <instance-id or instance-name>