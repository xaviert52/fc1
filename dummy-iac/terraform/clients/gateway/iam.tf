resource "aws_iam_role_policy" "ecs_exec_ssm" {
  name = "ecs-exec-ssm"

  role = element(
    split("/", data.terraform_remote_state.ecs.outputs.ecs_task_role_arn),
    length(split("/", data.terraform_remote_state.ecs.outputs.ecs_task_role_arn)) - 1
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
