[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = $vardir/ssl

[agent]
report          = true
pluginsync      = true
organisation    = ${organisation}
environment     = ${environment}
server          = ${server}
ca_server       = ${ca_server}
