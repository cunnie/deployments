# Create Infrastructure for sslip.io DNS server on AWS
#
# Use Graviton (ARM) instance type because I'm interested in a non-Intel
# architecture.
#
# Thanks
# https://medium.com/@mattias.holmlund/setting-up-ipv6-on-amazon-with-terraform-e14b3bfef577

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
  description = "The Elastic IP of the k8s worker"
}

resource "aws_vpc" "k8s" {
  cidr_block                       = "10.240.0.0/16"
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "k8s"
  }
}

resource "aws_subnet" "k8s" {
  vpc_id            = aws_vpc.k8s.id
  cidr_block        = cidrsubnet(aws_vpc.k8s.cidr_block, 8, 1) # 8: "/16" → "/24" 1: "10.240.0.0" → "10.240.1.0"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.k8s.ipv6_cidr_block, 8, 0)
  availability_zone = "us-east-1f" # t4g's are only available in us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
  tags = {
    Name = "k8s"
  }
}

# No security groups-based firewall; the networking will be complicated enough
# without worrying about security groups.

resource "aws_security_group" "allow_everything" {
  name        = "allow_everything"
  description = "we are bold, we are brave, we are naked (as far as firewalls are concerned)"
  vpc_id      = aws_vpc.k8s.id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_everything"
  }
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id
}

resource "aws_default_route_table" "k8s" {
  default_route_table_id = aws_vpc.k8s.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.k8s.id
  }
}

resource "aws_route_table_association" "k8s" {
  subnet_id      = aws_subnet.k8s.id
  route_table_id = aws_default_route_table.k8s.id
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDksYxt4WhOyDZA/5jtY68Jp1NXDwj5yTiXvu5e0htyt1Z+oyp2exiNiiHcZ49e/DIb/+pLopxZJXndM+osYex7MuJ5Z2NLc9Dymj+zGKbfDatflcyNcqULA+Dtl4wrfEFWhZC0WoHY7f94MtszW0kU4jSuiP0IkQGw47XrsPe8irwQJK1O8mj5ygm6dsMcSRUV0fItltXGLQ95ANxg2YLOL9Kpbul2c6s08qcWJ35QBHTZyBP8Hryb2CkUdbW6sJCv5GuQ9DG0D2q5kYpSsznd3tnvl7AC3nUI4ENFaYF9LlYp28ohRG2LHl6A/r3u8ghYqSH5Qz4PV4CxX/Z0EEoSXflFWgYedb/5nYsEkly0DOpmOULqkobJg8ki3gBOzL5LEO8uI6uGzJz5XSbRzSDSTDPpUxcm5I5OA9kVTSq1jE7wxn4IA6kd1UvXRc2w/yxMa43W0L22lWHJjFIIbrYe6ymy6IxMmKLJpdh38aRXv7PzCM+rUmnm4Fpcko9xF68= brian.cunnie@gmail.com"
}

# remember, the user is "fedora" not "ec2-user"
#
# ssh -i ~/.ssh/aws fedora@w.x.y.z
# curl https://raw.githubusercontent.com/cunnie/bin/master/install_k8s_worker.sh | bash -x
resource "aws_instance" "k8s" {
  ami           = "ami-07b7fa952a4ad5fd2"
  key_name      = aws_key_pair.k8s.key_name
  instance_type = "t4g.micro"
  root_block_device {
    volume_size = 26 # the default 6 GB is too small; "/" is 86% full
  }
  availability_zone      = "us-east-1f" # t4g's are only available in us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
  vpc_security_group_ids = [aws_security_group.allow_everything.id]
  subnet_id              = aws_subnet.k8s.id
  private_ip             = cidrhost(cidrsubnet(aws_vpc.k8s.cidr_block, 8, 1), 23)        # 23 = worker-3
  ipv6_addresses         = [cidrhost(cidrsubnet(aws_vpc.k8s.ipv6_cidr_block, 8, 0), 23)] # 23 = worker-3

  tags = {
    Name = "k8s Fedora 33 aarch64"
  }
}

data "aws_eip" "k8s" {
  public_ip = var.aws_eip
}

resource "aws_eip_association" "k8s" {
  instance_id   = aws_instance.k8s.id
  allocation_id = data.aws_eip.k8s.id
}

output "k8s_elastic_IPv4" {
  value = var.aws_eip
}

output "k8s_public_IPv6" {
  value = [aws_instance.k8s.ipv6_addresses]
}
