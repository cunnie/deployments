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

resource "aws_instance" "terraform-example" {
  ami                    = "ami-07b7fa952a4ad5fd2"
  instance_type          = "t4g.micro"
  vpc_security_group_ids = ["sg-2bc1904f"]
  subnet_id              = "subnet-1c90ef6b"

  tags = {
    Name = "Fedora 33 aarch64"
  }
}
