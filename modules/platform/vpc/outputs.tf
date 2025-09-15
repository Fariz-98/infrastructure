output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The VPC ID"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "IDs of private subnets"
}

output "vpce_sg_id" {
  value       = aws_security_group.vpce_sg.id
  description = "Security group ID for VPC interface endpoints"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private route table ID"
}

output "s3_gateway_endpoint_id" {
  value       = try(aws_vpc_endpoint.gateway[0].id, null)
  description = "S3 gateway endpoint ID (if created)"
}

output "interface_endpoint_ids" {
  value       = [for _, ep in aws_vpc_endpoint.interfaces : ep.id]
  description = "Interface VPC endpoint IDs"
}
