module "windows-agent" {
  source = "../../"

  name = "windows-agent"
  key_pair = ""
  network_uuid = "${var.network_uuid}"
  image = "windows_2012_r2_std_eval_x86_64"
  flavor = "d1.medium"
  pool = "${var.pool}"
  node_type = "windows-agent"
  master_ip = "${var.master_ip}"
  master_hostname = "puppet-master"
  windows_admin_password = "${var.windows_admin_password}"
}
