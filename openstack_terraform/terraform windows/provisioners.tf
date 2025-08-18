# Provisioners
locals {
  master_domain = "${var.master_domain == "" ? var.domain : var.master_domain}"
  master_fqdn   = "${var.master_hostname}.${local.master_domain}"

  os_types = {
    "puppet-master"  = "posix",
    "puppet-compile" = "posix",
    "posix-agent"    = "posix",
    "windows-agent"  = "windows",
  }

  os_type = "${local.os_types[var.node_type]}"

  pre_provisioners = {
    "posix" = [
      # Hostname and /etc/hosts
      "sudo hostname ${local.hostname}",
      "echo $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) ${local.fqdn} ${local.hostname} | sudo tee -a /etc/hosts",

      # CSR attributes
      "sudo mkdir -p /etc/puppetlabs/puppet",
      "sudo tee /etc/puppetlabs/puppet/csr_attributes.yaml << YAML",
      "extension_requests:",
      "  pp_role: '${var.pp_role}'",
      "YAML",
    ],

    "windows" = [
      # Set FQDN
      "netdom computername %computername% /add:${local.fqdn}",

      # CSR attributes
      "mkdir %PROGRAMDATA%\\PuppetLabs\\puppet\\etc",
      "(",
      "    echo extension_requests:",
      "    echo   pp_role: '${var.pp_role}'",
      ") > %PROGRAMDATA%\\PuppetLabs\\puppet\\etc\\csr_attributes.yaml",
    ],
  }

  puppet_provisioners = {
    "puppet-master" = [
      # Autosign nodes from domain
      "echo '*.${var.domain}' | sudo tee /etc/puppetlabs/puppet/autosign.conf",

      # Download the Puppet Enterprise installer
      "while : ; do",
      "  until curl --max-time 300 -o pe-installer.tar.gz \"${var.pe_source_url}\"; do sleep 1; done",
      "  tar -xzf pe-installer.tar.gz && break",
      "done",

      # Install Puppet enterprise
      "cat > pe.conf <<-EOF",
      "${var.pe_conf}",
      "EOF",
      "sudo ./puppet-enterprise-*/puppet-enterprise-installer -c pe.conf",

      # Run Puppet a few times to finalise installation
      "until sudo /opt/puppetlabs/bin/puppet agent -t; do sleep 1; done",
    ],

    "compile-master" = [
      "echo '${var.master_ip} ${local.master_fqdn} ${var.master_hostname}' | sudo tee -a /etc/hosts",
      "curl -k 'https://${local.master_fqdn}:8140/packages/current/install.bash' | sudo bash -s main:dns_alt_names=${var.dns_alt_names} -- --puppet-service-ensure stopped",
    ]

    "posix-agent" = [
      "echo '${var.master_ip} ${local.master_fqdn} ${var.master_hostname}' | sudo tee -a /etc/hosts",
      "curl -k 'https://${local.master_fqdn}:8140/packages/current/install.bash' | sudo bash -s -- --puppet-service-ensure stopped",
    ],

    "windows-agent" = [
      "echo ${var.master_ip} ${local.master_fqdn} ${var.master_hostname} >> %windir%\\System32\\drivers\\etc\\hosts",
      "powershell -NoProfile -Command [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; ^",
      "                               $webClient = New-Object System.Net.WebClient; ^",
      "                               $webClient.DownloadFile('https://${local.master_fqdn}:8140/packages/current/install.ps1', 'install.ps1'); ^",
      "                               .\\install.ps1 main:certname=${local.fqdn} -PuppetServiceEnsure stopped -PuppetServiceEnable false",
    ],
  }


  post_provisioners = {
    "posix" = [
      # Run Puppet a few times to finalise installation
      "until sudo /opt/puppetlabs/bin/puppet agent -t; do sleep 1; done",

      # Start the Puppet service
      "sudo service puppet start",
    ],

    "windows" = [
      # Run Puppet a few times to finalise installation
      "powershell -NoProfile -Command \"& $env:programfiles'\\puppet labs\\puppet\\bin\\puppet' agent -t\"",
      "powershell -NoProfile -Command \"& $env:programfiles'\\puppet labs\\puppet\\bin\\puppet' agent -t\"",
      "powershell -NoProfile -Command \"& $env:programfiles'\\puppet labs\\puppet\\bin\\puppet' agent -t\"",

      # Re-enable Puppet service after disable above to avoid race condition
      "sc config puppet start= auto",

      # Reboot because Windows always needs reboots
      "shutdown /r /t 0",
    ],
  }

  pre_provisioner    = "${local.pre_provisioners[local.os_type]}"
  puppet_provisioner = "${local.puppet_provisioners[var.node_type]}"
  post_provisioner   = "${local.post_provisioners[local.os_type]}"

  all_provisioners = "${concat(local.pre_provisioner, local.puppet_provisioner, var.custom_provisioner, local.post_provisioner)}"
}
