output "puppet_master_ip" {
  value = "${module.puppet-master.public_ip}"
}

output "puppet_agent_ip" {
  value = "${module.puppet-agent.public_ip}"
}
