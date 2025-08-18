#!/usr/bin/env bash

ssh -t -t cloud@${node_name} << EOF
sudo -i
puppet agent -t
exit
exit
EOF