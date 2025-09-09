output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "vpce_sg_id" {
  value = aws_security_group.vpce_sg.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "s3_gateway_endpoint_id" {
  value = aws_vpc_endpoint.gateway.id
}

output "interface_endpoint_ids" {
  value = [for _, ep in aws_vpc_endpoint.interfaces : ep.id]
}