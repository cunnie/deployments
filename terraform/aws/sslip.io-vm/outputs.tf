output "sslip_io_elastic_IPv4" {
  value = var.aws_eip
}

output "sslip_io_public_IPv6" {
  value = [aws_instance.sslip_io.ipv6_addresses]
}
