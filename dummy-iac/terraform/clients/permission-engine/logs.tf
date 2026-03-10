resource "aws_cloudwatch_log_group" "keto" {
  name              = "/ecs/keto"
  retention_in_days = 7

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
