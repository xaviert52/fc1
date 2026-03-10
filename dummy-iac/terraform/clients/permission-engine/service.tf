resource "aws_service_discovery_service" "keto" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "dns-keto"
  dns_config {
    namespace_id = data.terraform_remote_state.vpc.outputs.aws_service_discovery_private_dns_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "dns-keto"
  }
}

resource "aws_security_group" "keto" {
  name        = "${var.project}-${var.environment}-keto-sg"
  description = "Security Group for Keto Authorization Service"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Regla de Entrada: API de Lectura (Check) y Escritura (Write)
  # Solo tráfico desde el Gateway
  ingress {
    description     = "Allow Internal traffic to Keto APIs"
    from_port       = 4466
    to_port         = 4467
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
  }

  ingress {
    description     = "Allow Internal traffic to Keto APIs"
    from_port       = 4466
    to_port         = 4467
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.notifications.outputs.notifications_security_group_id]
  }

  # Regla de Salida: Permitir todo (para bajar imágenes ECR, hablar con RDS en el futuro, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-keto"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_ecs_service" "keto" {
  name            = "${var.project}-${var.environment}-keto-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.keto.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    assign_public_ip = false
    security_groups = [
      aws_security_group.keto.id,
      data.terraform_remote_state.postgres.outputs.db_client_sg_id # <--- LLAVE A LA RDS
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.keto[0].arn
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "keto"
  }
}

resource "aws_ecr_repository" "keto" {
  name                 = "${var.project}-${var.environment}-keto"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}
