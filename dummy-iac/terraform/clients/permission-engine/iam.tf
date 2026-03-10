resource "aws_iam_role" "keto_execution" {
  name = "${var.project}-${var.environment}-keto-execution"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "ecs-tasks.amazonaws.com" }, Effect = "Allow" }]
  })
}

resource "aws_iam_role_policy_attachment" "keto_execution_basic" {
  role       = aws_iam_role.keto_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "keto_secrets_access" {
  name = "${var.project}-${var.environment}-keto-secrets-access"
  role = aws_iam_role.keto_execution.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["secretsmanager:GetSecretValue"], Effect = "Allow", Resource = aws_secretsmanager_secret.keto_dsn.arn }]
  })
}

resource "aws_iam_role" "keto_task" {
  name = "${var.project}-${var.environment}-keto-task"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "ecs-tasks.amazonaws.com" }, Effect = "Allow" }]
  })
}
