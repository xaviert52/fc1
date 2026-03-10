resource "aws_ecs_task_definition" "client_zero" {
  family                   = "pry-client-zero-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.terraform_remote_state.ecs.outputs.ecs_task_execution_role_arn
  task_role_arn            = data.terraform_remote_state.ecs.outputs.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "client-zero-container"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/pry-client-zero:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.client_zero.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "client-zero"
        }
      }
      environment = [
        {
          name  = "CLIENT_ID"
          value = var.client_id
        }
      ]
    }
  ])

  tags = {
    project     = var.project
    environment = var.environment
    component   = "task-definition"
    client_id   = var.client_id
  }
}
