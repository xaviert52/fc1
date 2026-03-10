# 1. Bóveda central de Plataforma
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.terraform_remote_state.postgres.outputs.db_credentials_secret_arn
}

# 2. Secreto específico para Notificaciones
resource "aws_secretsmanager_secret" "notifications_db_pass" {
  name                    = "${var.project}-${var.environment}-notif-dbpass-secure"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "notifications_db_pass_version" {
  secret_id = aws_secretsmanager_secret.notifications_db_pass.id
  # Extraemos específicamente la clave "notifications" generada en la Fase 1
  secret_string = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["notifications"]
}

resource "aws_ecs_task_definition" "notifications" {
  family                   = "${var.project}-${var.environment}-notifications"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "notifications"
      essential = true

      # Imagen dinámica referenciando tu ECR local
      image = "${aws_ecr_repository.notifications.repository_url}:v2"

      portMappings = [
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]

      # INYECCIÓN ZERO TRUST
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.notifications_db_pass.arn
        }
      ]

      environment = [
        { name = "DB_HOST", value = data.terraform_remote_state.postgres.outputs.db_endpoint },
        { name = "DB_USER", value = "notifications_user" },
        { name = "DB_NAME", value = "pry_negocio" },
        { name = "KETO_WRITE_URL", value = "http://dns-keto.pry.internal:4467" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.notifications.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "notifications"
        }
      }
    }
  ])

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "notifications"
  }
}
