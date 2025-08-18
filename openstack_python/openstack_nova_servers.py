#!/usr/bin/env python

import os
from novaclient import client as novaclient

username = os.environ['OS_USERNAME']
password = os.environ['OS_PASSWORD']
project_name = os.environ['OS_PROJECT_NAME']
project_id = os.environ['OS_PROJECT_ID']
auth_url = os.environ['OS_AUTH_URL']

nova = novaclient.Client(version='2.0', username=username, password=password,
                         project_id=project_id, auth_url=auth_url)

for server in nova.servers.list():
    print server.id, server.name

# for server in nova.flavors.list():
    # print flavor.id, flavor.name
