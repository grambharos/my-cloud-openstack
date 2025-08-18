#!/usr/bin/env bash

ssh -t -t $USER@${foreman} << EOF
sudo hammer host update --name ${node_name} --environment ${environment} --hostgroup ${hostgroup} --puppet-proxy ${server} --puppet-ca-proxy ${ca_server}
exit
EOF