output "etcd_endpoint" {
  value = "http://${aws_ecs_service.etcd.name}:2379"
}

output "efs_id" {
  value = aws_efs_file_system.etcd.id
}