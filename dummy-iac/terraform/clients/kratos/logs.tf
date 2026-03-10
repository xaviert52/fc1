resource "aws_cloudwatch_log_group" "kratos" {
  name              = "/ecs/kratos"
  retention_in_days = 7

  tags = {
    Project     = "pry"
    Environment = "sandbox"
  }
}
