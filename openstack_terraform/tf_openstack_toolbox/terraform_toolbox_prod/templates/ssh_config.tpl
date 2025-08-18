UseKeychain yes
ControlPersist 7200s
StrictHostKeyChecking no

Host shellserver.ams5.init1.cloud
    ServerAliveInterval 60
    ControlMaster auto
    ControlPath /tmp/ssh_mux_%C

Host ${node_ip}
    User ${node_user}
    IdentityFile ~/.ssh/id_rsa
    ProxyJump shellserver.ams5.init1.cloud
