#!/usr/bin/env bash

ssh -t -t $USER@foreman.ams5.init1.cloud << EOF
sudo hammer host update --name toolbox-4.cloud-prod.ams1.cloud --environment ams1_overlay --hostgroup toolbox --puppet-proxy foreman-proxy-1.cloud-prod.ams1.cloud --puppet-ca-proxy foreman-proxy-1.cloud-prod.ams1.cloud
exit
EOF