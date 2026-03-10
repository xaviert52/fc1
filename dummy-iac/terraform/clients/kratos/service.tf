resource "aws_security_group" "kratos" {
  name        = "${var.project}-${var.environment}-kratos-sg"
  description = "Security Group for Ory Kratos"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description     = "Gateway to Kratos public API"
    from_port       = 4433
    to_port         = 4433
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
  }

  ingress {
    description     = "Gateway to Kratos admin API (optional, lab)"
    from_port       = 4434
    to_port         = 4434
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    project     = var.project
    environment = var.environment
    component   = "security-group"
    service     = "kratos"
  }
}

resource "aws_ecr_repository" "kratos" {
  name = "${var.project}-${var.environment}-kratos"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "kratos"
  }
}

resource "aws_ecr_lifecycle_policy" "kratos" {
  repository = aws_ecr_repository.kratos.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


resource "aws_service_discovery_service" "dns-kratos" {
  count = var.enable_service_discovery ? 1 : 0

  name = "dns-kratos"

  dns_config {
    namespace_id = data.terraform_remote_state.vpc.outputs.aws_service_discovery_private_dns_namespace_id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "dns-kratos"
  }
}

resource "aws_ecs_service" "kratos" {
  name            = "${var.project}-${var.environment}-kratos-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.kratos.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  enable_execute_command = true

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    assign_public_ip = false
    security_groups = [
      aws_security_group.kratos.id,
      data.terraform_remote_state.postgres.outputs.db_client_sg_id # <--- LLAVE A LA RDS
    ]
  }


  service_registries {
    registry_arn = aws_service_discovery_service.dns-kratos[0].arn
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "kratos"
  }
}
