#!/usr/bin/env bash

ssh -t -t cloud@toolbox-4.cloud-prod.ams1.cloud << EOF
sudo -i
puppet agent -t
exit
exit
EOF