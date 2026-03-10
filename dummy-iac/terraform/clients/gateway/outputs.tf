output "gateway_security_group_id" {
  description = "Security Group ID of the APISIX Gateway"
  value       = aws_security_group.gateway.id
}

output "gateway_nlb_dns" {
  value = aws_lb.gateway_nlb.dns_name
}

output "nameservers_to_update_in_registrar" {
  description = "Ve a Route53 > Registered Domains y asegúrate que usen estos NS"
  value       = aws_route53_zone.main.name_servers
}
