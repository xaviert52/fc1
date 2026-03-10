# 1. Leemos el JSON de credenciales lógicas que creamos en ztp1 (Plataforma)
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.terraform_remote_state.postgres.outputs.db_credentials_secret_arn
}

# 2. Creación del Secreto DSN para Kratos (Inyección Segura)
resource "aws_secretsmanager_secret" "kratos_dsn" {
  name                    = "${var.project}-${var.environment}-kratos-dsn-secure"
  recovery_window_in_days = 0
}

# 3. Construimos el DSN extrayendo la clave "master" del secreto centralizado
resource "aws_secretsmanager_secret_version" "kratos_dsn_version" {
  secret_id     = aws_secretsmanager_secret.kratos_dsn.id
  secret_string = "postgres://kratos:${jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["master"]}@${data.terraform_remote_state.postgres.outputs.db_endpoint}/kratos?sslmode=require"
}

resource "aws_ecs_task_definition" "kratos" {
  family                   = "kratos"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = aws_iam_role.kratos_execution.arn
  task_role_arn      = aws_iam_role.kratos_task.arn

  # EFS AMPUTADO DEFINITIVAMENTE DE ESTE BLOQUE

  container_definitions = jsonencode([
    {
      name      = "kratos"
      essential = true

      # Imagen Inmutable de Producción
      image = "${aws_ecr_repository.kratos.repository_url}:v1-immutable"

      portMappings = [
        { containerPort = 4433, hostPort = 4433, protocol = "tcp" },
        { containerPort = 4434, hostPort = 4434, protocol = "tcp" }
      ]

      entryPoint = ["sh", "-c"]
      command    = ["kratos migrate sql -e --yes && kratos serve -c /etc/config/kratos.yaml"]

      # INYECCIÓN ZERO TRUST
      secrets = [
        {
          name      = "DSN"
          valueFrom = aws_secretsmanager_secret.kratos_dsn.arn
        }
      ]

      environment = [
        { name = "KRATOS_CONFIG", value = "/etc/config/kratos.yaml" },
        { name = "LOG_LEVEL", value = "debug" },
        { name = "OAUTH2_PROVIDER_URL", value = "http://dns-hydra.pry.internal:4445" },
        { name = "SERVE_PUBLIC_BASE_URL", value = "https://api.ztest.click/kratos/" },
        { name = "SERVE_ADMIN_BASE_URL", value = "http://dns-kratos.pry.internal:4434/" },
        { name = "COOKIES_DOMAIN", value = "ztest.click" },
        { name = "COOKIES_SAME_SITE", value = "Lax" },
        { name = "SELFSERVICE_FLOWS_ERROR_UI_URL", value = "https://api.ztest.click/protected-zone/error" },
        { name = "SELFSERVICE_FLOWS_LOGIN_UI_URL", value = "https://api.ztest.click/protected-zone/login" },
        { name = "SELFSERVICE_FLOWS_REGISTRATION_UI_URL", value = "https://api.ztest.click/protected-zone/registration" },
        { name = "SELFSERVICE_DEFAULT_BROWSER_RETURN_URL", value = "https://api.ztest.click/protected-zone/" },
        { name = "SELFSERVICE_ALLOWED_RETURN_URLS", value = "https://api.ztest.click/protected-zone/,https://api.ztest.click/" },
        { name = "SELFSERVICE_FLOWS_RECOVERY_UI_URL", value = "https://api.ztest.click/protected-zone/recovery" },
        { name = "SELFSERVICE_FLOWS_SETTINGS_UI_URL", value = "https://api.ztest.click/protected-zone/settings" },
        { name = "SELFSERVICE_FLOWS_VERIFICATION_UI_URL", value = "https://api.ztest.click/protected-zone/verification" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.kratos.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "kratos"
        }
      }
    }
  ])

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "kratos"
  }
}
