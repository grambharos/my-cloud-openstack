data_dir = "/opt/consul"
ui_config{
  enabled = true
}
server = true
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
bootstrap_expect=3
retry_join = ["nomad-server-1","nomad-server-2","nomad-server-3"]