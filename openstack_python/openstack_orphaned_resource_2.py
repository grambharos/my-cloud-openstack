import os
import sys
import json
from termcolor import colored, cprint
from datetime import datetime
from keystoneauth1.identity import v2
from keystoneauth1 import session as ka_session
from keystoneclient.v3 import client as kclient
from novaclient import client as nclient
from neutronclient.v2_0 import client as neuclient
from cinderclient import client as cclient
from glanceclient.v2 import client as glclient

username = os.environ['OS_USERNAME']
password = os.environ['OS_PASSWORD']
auth_url = os.environ['OS_AUTH_URL']
region = os.environ['OS_REGION_NAME']


def usage():
    print "openstack_orphaned_resource.py <object> where object is one or more of",
    print "'networks', 'routers', 'subnets', 'floatingips', 'ports', 'servers', 'volumes', 'images' or 'all'"


def myconverter(o):
    if isinstance(o, datetime):
        return o.__str__()


def print_json(data):
    print(json.dumps(data, sort_keys=True, indent=7,
                     separators=(',', ':'), default=myconverter))


def get_session():
    auth = v2.Password(auth_url=auth_url, username=username,
                       password=password, tenant_name="admin")
    session = ka_session.Session(auth=auth)
    return session


def get_orphaned_neutron_objects(object):
    projectids = get_projectids()
    projectids.append("")
    objects = getattr(neutron, 'list_' + object)()
    orphans = []
    for object in objects.get(object):
        if object['tenant_id'] not in projectids:
            orphans.append(object['id'])
    return orphans


def get_orphaned_nova_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    for server in nova.servers.list(search_opts={'all_tenants': 1}):
        if server.tenant_id not in projectids:
           orphans.append(server.id)
    return orphans


def get_orphaned_security_group_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    for secgroup in nova.security_groups.list(search_opts={'all_tenants': 1}):
        if secgroup.tenant_id not in projectids:
           orphans.append(secgroup.id)
    return orphans


def get_orphaned_volumes_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    for volume in cinder.volumes.list(search_opts={'all_tenants': 1}):
        if getattr(volume, 'os-vol-tenant-attr:tenant_id') not in projectids:
           orphans.append(volume.id)
    return orphans


def get_orphaned_images_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    for image in glance.images.list():
        if image.owner not in projectids:
           orphans.append(image.owner)
    return orphans


def get_orphaned_security_group_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    for secgroup in nova.security_groups.list(search_opts={'all_tenants': 1}):
        if secgroup.tenant_id not in projectids:
           orphans.append(secgroup.id)
    return orphans


def get_orphaned_keypairs_objects():
    projectids = get_projectids()
    projectids.append("")
    orphans = []
    print nova.keypairs.list()
    for keypair in nova.keypairs.list():
        print keypair
        sys.exit(0)
        if keypair.tenant_id not in projectids:
           orphans.append(secgroup.id)
    return orphans


session = get_session()
keystone = kclient.Client(session=session)
neutron = neuclient.Client(session=session, region_name=region)
nova = nclient.Client(2, session=session, region_name=region)
cinder = cclient.Client('2', session=session, region_name=region)
glance = glclient.Client('2', session=session, region_name=region)

projectids = [project.id for project in keystone.projects.list()]


def get_projectids():
    return projectids


if __name__ == '__main__':
    if len(sys.argv) > 1:
        if sys.argv[1] == 'all':
            objects = ['networks', 'routers', 'subnets',
                       'floatingips', 'ports', 'servers', 'volumes', 'images']
        else:
            objects = sys.argv[1:]
        for object in objects:
            if object == "servers":
              orphans = get_orphaned_nova_objects()
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
            elif object == "keypairs":
              orphans = get_orphaned_keypairs_objects()
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
            elif object == "volumes":
              orphans = get_orphaned_volumes_objects()
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
            elif object == "secgroups":
              orphans = get_orphaned_security_group_objects()
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
            elif object == "images":
              orphans = get_orphaned_images_objects()
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
            else:
              orphans = get_orphaned_neutron_objects(object)
              print len(orphans), 'orphan(s) found of type', colored(object, 'green')
              print '\n'.join(map(str, orphans))
    else:
        usage()
        sys.exit(1)
