resource "aws_cloudwatch_log_group" "client_zero" {
  name              = "/ecs/pry/sandbox/client-zero"
  retention_in_days = 14

  tags = {
    project     = var.project
    environment = var.environment
    component   = "logs"
    client_id   = var.client_id
  }
}
