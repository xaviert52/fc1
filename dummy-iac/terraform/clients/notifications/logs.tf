resource "aws_cloudwatch_log_group" "notifications" {
  name              = "/ecs/${var.project}-${var.environment}-notifications"
  retention_in_days = 7
}
