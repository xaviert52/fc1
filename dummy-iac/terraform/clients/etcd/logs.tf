resource "aws_cloudwatch_log_group" "etcd" {
  name              = "/ecs/pry-etcd"
  retention_in_days = 14

  tags = {
    project     = var.project
    environment = var.environment
    service     = "etcd"
  }
}