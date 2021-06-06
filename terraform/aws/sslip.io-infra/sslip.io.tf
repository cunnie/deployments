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

resource "aws_vpc" "sslip_io" {
  cidr_block                       = "10.241.0.0/16"
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "sslip_io"
  }
}

resource "aws_subnet" "sslip_io" {
  vpc_id            = aws_vpc.sslip_io.id
  cidr_block        = cidrsubnet(aws_vpc.sslip_io.cidr_block, 8, 0) # 8: "/16" → "/24" 1: "10.240.0.0" → "10.240.0.0"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.sslip_io.ipv6_cidr_block, 8, 0)
  availability_zone = "us-east-1f" # t4g's are only available in us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
  tags = {
    Name = "sslip_io"
  }
}

# No security groups-based firewall
resource "aws_security_group" "allow_everything" {
  name        = "allow_everything"
  description = "we are bold, we are brave, we are naked (as far as firewalls are concerned)"
  vpc_id      = aws_vpc.sslip_io.id
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

resource "aws_internet_gateway" "sslip_io" {
  vpc_id = aws_vpc.sslip_io.id
}

resource "aws_default_route_table" "sslip_io" {
  default_route_table_id = aws_vpc.sslip_io.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sslip_io.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.sslip_io.id
  }
}

resource "aws_route_table_association" "sslip_io" {
  subnet_id      = aws_subnet.sslip_io.id
  route_table_id = aws_default_route_table.sslip_io.id
}
