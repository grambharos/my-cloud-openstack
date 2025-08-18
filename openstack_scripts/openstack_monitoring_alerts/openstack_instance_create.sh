#!/usr/bin/env bash

#####################################################################
#script to create an instance                                       #
#this is only for https://github.es.ecg.tools/ in your git folder  #
#Author: germio.rambharos                                        #
#####################################################################

set -x

region=ol-ams1
project=dev-grambharos
instance=test-focal-now
flavor_id=0010
image_id=0d8d9f68-ef3b-487e-b4a1-d5c31f94dc5e
network_id=27300fa7-3adc-40f3-8cb7-a71c6cb759d5
mykey=grambharos

nova boot $instance --flavor $flavor_id --image $image_id --nic net-id=$network_id --key-name $mykey