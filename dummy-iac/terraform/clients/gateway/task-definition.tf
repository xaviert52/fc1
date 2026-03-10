resource "aws_ecs_task_definition" "gateway" {
  family                   = "pry-gateway-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = data.terraform_remote_state.ecs.outputs.ecs_task_execution_role_arn
  task_role_arn      = data.terraform_remote_state.ecs.outputs.ecs_task_role_arn

  container_definitions = jsonencode([
    # ============================================================
    # APISIX GATEWAY
    # ============================================================
    {
      name      = "gateway-container"
      image     = "${aws_ecr_repository.gateway.repository_url}:labc2"
      essential = true

      portMappings = [
        {
          containerPort = 9080
          hostPort      = 9080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ETCD_HOST", value = "dns-etcd.pry.internal:2379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.gateway.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "gateway"
        }
      }
    }
  ])

  tags = {
    project     = var.project
    environment = var.environment
    component   = "task-definition"
    client_id   = var.client_id
  }
}
