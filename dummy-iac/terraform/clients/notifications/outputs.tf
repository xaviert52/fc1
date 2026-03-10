output "notifications_service_name" {
  value = aws_ecs_service.notifications.name
}

output "notifications_security_group_id" {
  value = aws_security_group.notifications.id
}

output "notifications_ecr_repository_url" {
  value = aws_ecr_repository.notifications.repository_url
}
