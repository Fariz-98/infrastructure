output "alb_sg_id" {
  value = module.alb.alb_sg_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "http_listener_arn" {
  value = module.alb.http_listener_arn
}

output "https_listener_arn" {
  value = module.alb.https_listener_arn
}

output "alb_arn_suffix" {
  value = module.alb.alb_arn_suffix
}