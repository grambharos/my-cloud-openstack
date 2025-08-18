from ldap3 import Server, Connection, ALL, ObjectDef, Reader, Writer
from ldap3.core.exceptions import LDAPSocketOpenError
import logging
import argparse
import base64
import sys
import re
from jira import JIRA
from getpass import getpass, getuser

BASE = "ou=classifieds,o=ebay"
useruid = "uid={user},ou=People,{base}"
groupcn = "cn={group},ou=Group,{base}"
jirahost = "https://jira.corp.ebay.com"


# Set logging level
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# TODO Try enable debug logging
from ldap3.utils.log import set_library_log_activation_level, EXTENDED
set_library_log_activation_level(EXTENDED)


def processjira(jiranumber, ldaphost, ldapport, username, doit):
    jira = JIRA(jirahost, basic_auth=(username, getpass('Jira Password: ')))
    issue = jira.issue(jiranumber)

    # LDap connection
    try:
        server = Server(host=ldaphost, port=ldapport, get_info=ALL)
        conn = Connection(server, auto_bind=True, )
        logger.info(conn)
    except LDAPSocketOpenError:
        logger.error('Problems connecting to the ldap server')
        sys.exit(1)

    # Start a TLS session
    #conn.start_tls()


    # Base user schema
    obj_ecguser = ObjectDef(['top', 'person', 'organizationalPerson',
                             'inetOrgPerson', 'posixAccount', 'shadowAccount',
                             'gosaAccount'], conn)

    # Add the password policy entry attribute
    obj_ecguser.add_attribute('pwdPolicySubentry')

    # Base group schema object
    obj_ecggroup = ObjectDef(['top', 'posixGroup', 'groupOfNames'], conn)

    if issue.fields.issuetype.id == '10900':
        logger.info('ldap system user request')

        if not doit:
            logger.info('Checking jira status')
            if issue.fields.status.name == "Approved":
                logger.info('Jira approved')
            else:
                logger.error('Jira not approved, exiting')
                sys.exit(1)

        try:
            description = issue.fields.description.strip()
            ldapusername = checkdupldapuser(issue.fields.customfield_13963.strip(), conn)
            group = checkldapgroup('norights', conn)
            email = issue.fields.customfield_13979.strip()
            shell = issue.fields.customfield_15950.value.strip().lower()
            manager = issue.fields.reporter.name.strip()
        except ValueError as e:
            logger.error(e)
            sys.exit(1)

        w = Writer(conn, obj_ecguser)
        newuser = w.new('uid={0},ou=People,ou=classifieds,o=ebay'.format(ldapusername))
        newuser.description = "{0} {1}".format(jiranumber, description[:40].rstrip('-= '))
        newuser.sn = ldapusername
        newuser.cn = ldapusername
        newuser.uidnumber = str(getnextuid(conn))
        newuser.mail = email
        newuser.gidnumber = str(group)
        newuser.manager = 'uid={0},ou=People,ou=classifieds,o=ebay'.format(checkldapuser(manager, conn))
        newuser.homedirectory = '/media/home/'+ldapusername
        newuser.pwdPolicySubentry = 'cn=no-pw-aging,ou=Policies,ou=classifieds,o=ebay'

        if shell.lower() == 'yes':
            newuser.loginshell = '/bin/bash'

        # Print out the changes before committing
        print(newuser)

        correct = input('Are the values correct? Enter YES to commit to ldap: ')

        if correct == 'YES':
            # Rebind with admin creds
            conn.rebind(user="uid={0},ou=People,ou=classifieds,o=ebay".format(username),
                        password=getpass('Ldap password: '))
            try:
                newuser.entry_commit_changes()
                print(newuser)
                print(conn)
            except LDAPCursorError as e:
                print('Adding new user failed : {0}'.format(e))

        else:
            print('Not correct, exiting')
            sys.exit(1)

    elif issue.fields.issuetype.id == '10901':
        logger.info('ldap group request')

        try:
            group_name = checkldapdupgroup(issue.fields.customfield_15951.strip(), conn)
            description = issue.fields.description.strip()

        except ValueError as e:
            logger.error(e)
            sys.exit(1)

        w = Writer(conn, obj_ecggroup)

        newgroup = w.new('cn={0},ou=Group,ou=classifieds,o=ebay'.format(group_name))
        newgroup.description = "{0} {1}".format(jiranumber, description[:40].rstrip('-= '))
        newgroup.businessCategory = 'Sailpoint'
        newgroup.gidnumber = str(getnextgid(conn))

        print(newgroup)
        correct = input('Are the values correct? Enter YES to commit to ldap: ')
        if correct == 'YES':
            # Rebind with admin creds
            conn.rebind(user="uid={0},ou=People,ou=classifieds,o=ebay".format(username),
                        password=getpass('Ldap password: '))
            try:
                newgroup.entry_commit_changes()
                print(newgroup)
                print(conn)
            except LDAPCursorError as e:
                print('Adding new group failed: {0}'.format(e))
                print(conn)
        else:
            print('Not correct, exiting')
            sys.exit(1)

    else:
        logger.error('Unknown issue type')
        sys.exit(1)


# Check that the username does not exist in the current ldap
def checkldapuser(username, conn):
    logger.info('Checking username: {0}'.format(username))

    obj_ecguser = ObjectDef(['top', 'person', 'organizationalPerson',
                             'inetOrgPerson', 'posixAccount', 'shadowAccount',
                             'gosaAccount'], conn)

    reader = Reader(conn, obj_ecguser, "ou=classifieds,o=ebay", "(uid={0})".format(username))
    search = reader.search()

    if len(search) != 0:
        logger.info('Username found: {0}'.format(username))
        return username
    else:
        logger.error('User missing: ' + username)
        raise ValueError('Username not found: {0}'.format(username))


# Check that the username does not exist in the current ldap
def checkdupldapuser(dupusername, conn):
    logger.info('Checking duplicate for requested username: {0}'.format(dupusername))

    logger.info('Checking username does not contain underscores')
    if "_" in dupusername:
        raise ValueError('Name contains underscores: {0}'.format(dupusername))

    # Check the username pattern matches the check in openstack
    # ldapfilter core.py
    logger.info('Checking user will work in keystone {0}'.format(dupusername))
    valid_username = re.compile('^[a-z\-]+\d*$')
    if not valid_username.match(dupusername):
        logger.info('Username will not work in keystone/openstack {0}'.format(dupusername))
        raise ValueError('Invalid username {0}'.format(dupusername))

    obj_ecguser = ObjectDef(['top', 'person', 'organizationalPerson',
                             'inetOrgPerson', 'posixAccount', 'shadowAccount',
                             'gosaAccount'], conn)

    reader = Reader(conn, obj_ecguser, "ou=classifieds,o=ebay", "(uid={0})".format(dupusername))
    search = reader.search()

    if len(search) == 0:
        logger.info('No duplicate username found')
        return dupusername
    else:
        logger.error('Found: ' + search[0].entry_dn)
        raise ValueError('Duplicate username found: {0}'.format(dupusername))


# Check that the ldap group exists in the current groups
def checkldapgroup(defaultldapgroup, conn):
    logger.info('Fetching the GID for group: {0}'.format(defaultldapgroup))

    obj_ecggroup = ObjectDef(['top', 'posixGroup', 'groupOfNames'], conn)

    reader = Reader(conn, obj_ecggroup, "ou=classifieds,o=ebay", "(cn={0})".format(defaultldapgroup))
    search = reader.search()

    if len(search) == 1:
        logger.info('Found GID: {0}'.format(search[0].gidnumber))
        return search[0].gidnumber
    elif len(search) > 1:
        raise ValueError('Multiple matching groups found')
    else:
        raise ValueError('Ldap group not found: {0}'.format(defaultldapgroup))


# Check if the ldap group does not exists
def checkldapdupgroup(dupldapgroup, conn):
    logger.info('Checking if group already exists: {0}'.format(dupldapgroup))

    obj_ecggroup = ObjectDef(['top', 'posixGroup', 'groupOfNames'], conn)

    reader = Reader(conn, obj_ecggroup, "ou=classifieds,o=ebay", "(cn={0})".format(dupldapgroup))
    search = reader.search()

    if len(search) >= 1:
        logger.error('Found group: {0}'.format(search[0].cn))
        raise ValueError('Duplicate LDAP group found')
    elif len(search) == 0:
        logger.info('No duplicate group found')
        return dupldapgroup


# Generate the Next UID/GID functions
def getnextuid(conn):
    logger.info('Generating next UID')
    conn.search("ou=People,ou=classifieds,o=ebay", "(uidNumber=*)", attributes=["uidNumber"])
    uids = [uid.uidNumber.value for uid in conn.entries if 60000 < int(uid.uidNUmber.value) < 65000]

    try:
        uid = int(max(uids) + 1)
        logger.info('Next UID is: {0}'.format(uid))
        return uid
    except ValueError:
        print('No user IDs available')
        sys.exit(1)


def getnextgid(conn):
    logger.info('Generating next GID')
    conn.search("ou=Group,ou=classifieds,o=ebay", "(gidNumber=*)", attributes=["gidNumber"])
    gids = [gid.gidNumber.value for gid in conn.entries if 60000 < int(gid.gidNumber.value) < 65000]
    try:
        return int(max(gids) + 1)
    except ValueError:
        print('No group IDs available')
        sys.exit(1)


def createldap(**kwargs):
    jiranumber = kwargs['jiranumber']
    ldaphost = kwargs['ldaphost']
    ldapport = kwargs['ldapport']
    username = kwargs['username']
    doit = kwargs['doit']

    processjira(jiranumber, ldaphost, ldapport, username, doit)


def main():

    options = argparse.ArgumentParser(description="Ldap helper script")
    options.add_argument('-H', '--host', help='Host', default='ldaps://ldapmaster.cloud-prod.ams1.cloud')
    options.add_argument('-p', '--port', help='Port', type=int, default=636)
    options.add_argument('--jira', required=True)
    options.add_argument('--username', default=getuser(), help='Username for jira and ldap, defaults to {0}'.format(getuser()))
    options.add_argument('--doit', default=0, help='Ignore the jira approved status')
    args = options.parse_args()

    createldap(ldaphost=args.host, ldapport=args.port, jiranumber=args.jira, username=args.username, doit=args.doit)


if __name__ == '__main__':
    main()
