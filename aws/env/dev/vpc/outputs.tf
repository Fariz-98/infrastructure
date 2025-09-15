output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "vpce_sg_id" {
  value = module.vpc.vpce_sg_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "s3_gateway_endpoint_id" {
  value = module.vpc.s3_gateway_endpoint_id
}

output "interface_endpoint_ids" {
  value = module.vpc.interface_endpoint_ids
}