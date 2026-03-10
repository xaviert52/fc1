resource "aws_cloudwatch_log_group" "hydra" {
  name              = "/ecs/hydra"
  retention_in_days = 7

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "hydra"
  }
}
