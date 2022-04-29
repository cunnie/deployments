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

resource "aws_key_pair" "sslip_io" {
  key_name   = "sslip_io"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDksYxt4WhOyDZA/5jtY68Jp1NXDwj5yTiXvu5e0htyt1Z+oyp2exiNiiHcZ49e/DIb/+pLopxZJXndM+osYex7MuJ5Z2NLc9Dymj+zGKbfDatflcyNcqULA+Dtl4wrfEFWhZC0WoHY7f94MtszW0kU4jSuiP0IkQGw47XrsPe8irwQJK1O8mj5ygm6dsMcSRUV0fItltXGLQ95ANxg2YLOL9Kpbul2c6s08qcWJ35QBHTZyBP8Hryb2CkUdbW6sJCv5GuQ9DG0D2q5kYpSsznd3tnvl7AC3nUI4ENFaYF9LlYp28ohRG2LHl6A/r3u8ghYqSH5Qz4PV4CxX/Z0EEoSXflFWgYedb/5nYsEkly0DOpmOULqkobJg8ki3gBOzL5LEO8uI6uGzJz5XSbRzSDSTDPpUxcm5I5OA9kVTSq1jE7wxn4IA6kd1UvXRc2w/yxMa43W0L22lWHJjFIIbrYe6ymy6IxMmKLJpdh38aRXv7PzCM+rUmnm4Fpcko9xF68= brian.cunnie@gmail.com"
}

resource "aws_instance" "sslip_io" {
  ami           = "ami-065e36ba0c5d7ccc6" # "Ubuntu 22.04 - Jammy Jellyfish (arm64)"
  key_name      = aws_key_pair.sslip_io.key_name
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
