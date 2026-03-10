output "aws_security_group_keto" {
  value = aws_security_group.keto.id
}

output "service_discovery_arn" {
  value = aws_service_discovery_service.keto[0].arn
}
