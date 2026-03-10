# Extraemos la bóveda de la plataforma
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.terraform_remote_state.postgres.outputs.db_credentials_secret_arn
}

# Construimos el DSN dinámico para Hydra
resource "aws_secretsmanager_secret" "hydra_dsn" {
  name                    = "${var.project}-${var.environment}-hydra-dsn-secure"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "hydra_dsn_version" {
  secret_id = aws_secretsmanager_secret.hydra_dsn.id
  # FIX: Usamos el usuario 'kratos' (dueño de las tablas) y escapamos los caracteres especiales con urlencode()
  # secret_string = "postgres://hydra_user:${jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["hydra"]}@${data.terraform_remote_state.postgres.outputs.db_endpoint}/hydra?sslmode=require"
  secret_string = "postgres://kratos:${urlencode(jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["master"])}@${data.terraform_remote_state.postgres.outputs.db_endpoint}/hydra?sslmode=require"
}

# 3. Secreto del Sistema de Hydra (Encriptación de Cookies/Tokens)
resource "aws_secretsmanager_secret" "hydra_system" {
  name                    = "${var.project}-${var.environment}-hydra-system-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "hydra_system_version" {
  secret_id     = aws_secretsmanager_secret.hydra_system.id
  secret_string = var.system_secret
}

resource "aws_ecs_task_definition" "hydra" {
  family                   = "${var.project}-${var.environment}-hydra"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "hydra"
      image     = "${aws_ecr_repository.hydra.repository_url}:v2.2.0"
      cpu       = 0
      essential = true
      command   = ["serve", "all", "--sqa-opt-out"]
      portMappings = [
        {
          containerPort = 4444
          hostPort      = 4444
          protocol      = "tcp"
        },
        {
          containerPort = 4445
          hostPort      = 4445
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "DSN"
          valueFrom = aws_secretsmanager_secret.hydra_dsn.arn
        },
        {
          name      = "SECRETS_SYSTEM"
          valueFrom = aws_secretsmanager_secret.hydra_system.arn
        }
      ]

      environment = [
        # ---------------------------------------------------------
        # CORRECCIONES DE REDIRECCIÓN (Browser-facing URLs)
        # ---------------------------------------------------------
        {
          # El Issuer es la identidad pública de Hydra
          name  = "URLS_SELF_ISSUER"
          value = "https://api.ztest.click"
        },
        {
          # Login: Redirige al usuario a la API pública de Kratos (vía APISIX)
          name  = "URLS_LOGIN"
          value = "https://api.ztest.click/kratos/self-service/login/browser"
        },
        {
          # Consent: Redirige a la UI pública (Ojo: Requerirá implementación futura)
          name  = "URLS_CONSENT"
          value = "https://api.ztest.click/consent"
        },
        {
          # Error: Para depurar problemas en el navegador
          name  = "URLS_ERROR"
          value = "https://api.ztest.click/error"
        },
        # ---------------------------------------------------------
        {
          name  = "SERVE_PUBLIC_PORT"
          value = "4444"
        },
        {
          name  = "SERVE_ADMIN_PORT"
          value = "4445"
        },
        {
          name  = "SERVE_PUBLIC_CORS_ENABLED"
          value = "true"
        },
        {
          name  = "SERVE_PUBLIC_CORS_ALLOWED_ORIGINS"
          value = "*"
        },
        {
          name  = "LOG_LEVEL"
          value = "debug"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.hydra.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
