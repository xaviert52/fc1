# Leemos el JSON de contraseñas lógicas que creamos en ztp1
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.terraform_remote_state.postgres.outputs.db_credentials_secret_arn
}

# Creamos un secreto exclusivo para Keto usando su propia contraseña
resource "aws_secretsmanager_secret" "keto_dsn" {
  name                    = "${var.project}-${var.environment}-keto-dsn-secure"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "keto_dsn_version" {
  secret_id = aws_secretsmanager_secret.keto_dsn.id
  #usamos el usuario maestro porque keto ya inicio con esto
  # secret_string = "postgres://keto_user:${jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["keto"]}@${data.terraform_remote_state.postgres.outputs.db_endpoint}/keto?sslmode=require&max_conns=20&max_idle_conns=4"
  secret_string = "postgres://kratos:${jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["master"]}@${data.terraform_remote_state.postgres.outputs.db_endpoint}/keto?sslmode=require&max_conns=20&max_idle_conns=4"
}

resource "aws_ecs_task_definition" "keto" {
  family                   = "keto"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  # Usamos sus nuevos roles aislados
  execution_role_arn = aws_iam_role.keto_execution.arn
  task_role_arn      = aws_iam_role.keto_task.arn

  # EFS AMPUTADO

  container_definitions = jsonencode([
    {
      name      = "keto"
      image     = "${aws_ecr_repository.keto.repository_url}:v1-immutable"
      essential = true

      portMappings = [
        { containerPort = 4466, hostPort = 4466 },
        { containerPort = 4467, hostPort = 4467 }
      ]

      command = ["serve", "all", "--config", "/etc/config/keto.yml"]

      secrets = [
        {
          name      = "DSN"
          valueFrom = aws_secretsmanager_secret.keto_dsn.arn
        }
      ]

      environment = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.keto.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "keto"
        }
      }
    }
  ])

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "keto"
  }
}
