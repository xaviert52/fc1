# Security Group propio de Hydra
resource "aws_security_group" "hydra" {
  name        = "${var.project}-${var.environment}-hydra-sg"
  description = "Security Group for Hydra Service"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Ingreso solo desde Gateway
  ingress {
    from_port       = 4444
    to_port         = 4445
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
  }

  ingress {
    description     = "Allow Internal Admin Traffic (Kratos)"
    from_port       = 4445
    to_port         = 4445
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.kratos.outputs.aws_security_group_kratos]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Cloud Map Service Discovery
resource "aws_service_discovery_service" "hydra" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "dns-hydra"

  dns_config {
    namespace_id = data.terraform_remote_state.vpc.outputs.aws_service_discovery_private_dns_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ECS Service
resource "aws_ecs_service" "hydra" {
  name            = "${var.project}-${var.environment}-hydra-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.hydra.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    assign_public_ip = false
    security_groups = [
      aws_security_group.hydra.id,
      data.terraform_remote_state.postgres.outputs.db_client_sg_id # <--- LLAVE A LA RDS
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.hydra[0].arn
  }
}

resource "aws_ecr_repository" "hydra" {
  name                 = "${var.project}-${var.environment}-hydra"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true # Permite destruir el repo aunque tenga imágenes (útil en sandbox)
}
