output "security_group_sslip_io_id" {
  value = aws_security_group.allow_everything.id
}

output "subnet_sslip_io_id" {
  value = aws_subnet.sslip_io.id
}

output "vpc_sslip_io_cidr_block" {
  value = aws_vpc.sslip_io.cidr_block
}

output "vpc_sslip_io_ipv6_cidr_block" {
  value = aws_vpc.sslip_io.ipv6_cidr_block
}
