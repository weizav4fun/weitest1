source "amazon-ebs" "baseline_ami" {
  region        =  "us-east-1"
  source_ami    =  "ami-0affd4508a5d2481b"
  instance_type =  "t2.medium"
  ssh_username  =  "centos"
  ami_name      =  "ami-base-${var.version}"

  access_key = var.access_key
  secret_key = var.secret_key

  tags = {
    OS_Version = "Centos7"
    Version = "${var.version}"
    Base_AMI_ID = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Name = "ami-base-${var.version}"
  }
}

build {
  sources = ["source.amazon-ebs.baseline_ami"]

  provisioner "shell" {
    inline = ["sudo yum install wget -y"]
  }

  # Install jxm_exporter
  provisioner "file" {
    source = "../common/scripts/jmx_exporter.sh"
    destination = "/home/centos/"
  }

  provisioner "shell" {
    inline = ["sudo bash /home/centos/jmx_exporter.sh ${var.jmx_exporter_version}"]
  }

  # Node exporter
  provisioner "file" {
    source = "../common/scripts/node_exporter.sh"
    destination = "/home/centos/"
  }

  provisioner "shell" {
    inline = ["sudo bash /home/centos/node_exporter.sh"]
  }


  # Configure logrotate
  provisioner "file" {
    source = "../common/scripts/configure_logrotate.sh"
    destination = "/home/centos/"
  }

  provisioner "shell" {
    inline = ["sudo bash /home/centos/configure_logrotate.sh", "rm /home/centos/configure_logrotate.sh"]
  }

  # Install AlienVault
  provisioner "file" {
    source = "../common/scripts/install_alienvault.sh"
    destination = "/home/centos/"
  }
  provisioner "shell" {
      inline = ["sudo bash /home/centos/install_alienvault.sh", "sudo rm /home/centos/install_alienvault.sh"]
  }

  provisioner "file" {
    source = "../common/scripts/install_carbon_black.sh"
    destination = "/home/centos/"
  }
  provisioner "file" {
    source = "../common/packages/cb-psc-sensor-rhel-2.11.0.460062.tar"
    destination = "/home/centos/"
  }
  provisioner "shell" {
      inline = ["sudo bash /home/centos/install_carbon_black.sh", "sudo rm /home/centos/install_carbon_black.sh"]
  }

  # Install PromTail
  provisioner "file" {
    source = "../common/scripts/install_promtail.sh"
    destination = "/home/centos/"
  }

  provisioner "shell" {
    inline = ["sudo bash /home/centos/install_promtail.sh", "rm /home/centos/install_promtail.sh"]
  }

  # Install ssm-agent
  provisioner "file" {
    source = "../common/scripts/install_ssm.sh"
    destination = "/home/centos/"
  }

  provisioner "shell" {
    inline = ["sudo bash /home/centos/install_ssm.sh", "rm /home/centos/install_ssm.sh"]
  }

  provisioner "file" {
    source = "../common/scripts/cis_remediation_scripts.sh"
    destination = "/home/centos/"
  }
  provisioner "shell" {
      inline = ["sudo bash /home/centos/cis_remediation_scripts.sh", "sudo rm /home/centos/cis_remediation_scripts.sh"]
  }

  # provisioner "inspec" {
  #   command = "cinc-auditor"
  #   profile = "./tests"
  # }

  post-processor "manifest" {
      output = "build_history.json"
      strip_path = true
  }
}