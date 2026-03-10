output "aws_security_group_hydra" {
  value = aws_security_group.hydra.id
}

output "service_discovery_arn" {
  value = aws_service_discovery_service.hydra[0].arn
}
