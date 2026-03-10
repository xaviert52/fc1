resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/ecs/pry/sandbox/gateway"
  retention_in_days = 14

  tags = {
    project     = var.project
    environment = var.environment
    component   = "logs"
    client_id   = var.client_id
  }
}
