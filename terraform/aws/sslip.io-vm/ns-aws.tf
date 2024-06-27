# Create Infrastructure for sslip.io DNS server on AWS
#
# Use Graviton (ARM) instance type because I'm interested in a non-Intel
# architecture.
#
# Thanks
# https://medium.com/@mattias.holmlund/setting-up-ipv6-on-amazon-with-terraform-e14b3bfef577
#
# NOTES:
# - check `/var/log/cloud-init-output.log` when troubleshooting faulty post-creation configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

variable "aws_eip" {
  type        = string
  description = "ns-aws.sslip.io IPv4"
}

# the following variables are from the ../sslip.io-infra outputs
variable "security_group_sslip_io_id" {
  type        = string
  description = "Security Group"
}

variable "subnet_sslip_io_id" {
  type        = string
  description = "Subnet"
}

variable "vpc_sslip_io_cidr_block" {
  type        = string
  description = "IPv4 CIDR"
}

variable "vpc_sslip_io_ipv6_cidr_block" {
  type        = string
  description = "IPv6 CIDR"
}

resource "aws_key_pair" "nono" {
  key_name   = "nono"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io"
}

resource "aws_instance" "sslip_io" {
  ami           = "ami-0eac975a54dfee8cb" # "Ubuntu Server 24.04 LTS (HVM), SSD Volume Type"
  key_name      = aws_key_pair.nono.key_name
  instance_type = "t4g.micro"
  root_block_device {
    volume_size = 26 # the default 6 GB is too small; "/" is 86% full
  }
  availability_zone      = "us-east-1f" # t4g's are only available in us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
  vpc_security_group_ids = [var.security_group_sslip_io_id]
  subnet_id              = var.subnet_sslip_io_id
  private_ip             = cidrhost(cidrsubnet(var.vpc_sslip_io_cidr_block, 8, 0), 10)        # 23 = worker-3
  ipv6_addresses         = [cidrhost(cidrsubnet(var.vpc_sslip_io_ipv6_cidr_block, 8, 0), 10)] # 23 = worker-3
  # check /var/log/cloud-init-output.log for output; curl http://169.254.169.254/latest/user-data for value
  user_data = "#!/bin/bash -x\necho ns-aws > /etc/hostname; hostname ns-aws; curl -L https://raw.githubusercontent.com/cunnie/bin/master/install_ns-aws.sh | bash -x"
  tags = {
    Name = "sslip_io Ubuntu aarch64"
  }
}

data "aws_eip" "sslip_io" {
  public_ip = var.aws_eip
}

resource "aws_eip_association" "sslip_io" {
  instance_id   = aws_instance.sslip_io.id
  allocation_id = data.aws_eip.sslip_io.id
}
