resource "aws_security_group" "notifications" {
  name        = "${var.project}-${var.environment}-notifications-sg"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "Allow Kratos to call notifications"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "dns-notifications" {
  count = var.enable_service_discovery ? 1 : 0

  name = "dns-notifications"

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
    Service     = "dns-notifications"
  }
}

resource "aws_ecr_repository" "notifications" {
  name = "${var.project}-${var.environment}-notifications"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"
}

resource "aws_security_group_rule" "ingress_kratos_to_notifications" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.kratos.outputs.aws_security_group_kratos
  security_group_id        = aws_security_group.notifications.id
  description              = "Allow traffic from Kratos (Explicit Rule)"
}

resource "aws_ecs_service" "notifications" {
  name            = "${var.project}-${var.environment}-notifications-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.notifications.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    assign_public_ip = false
    security_groups = [
      aws_security_group.notifications.id,
      data.terraform_remote_state.postgres.outputs.db_client_sg_id # <--- NUEVA LLAVE A LA RDS
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dns-notifications[0].arn
  }

  enable_execute_command = true

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "notifications"
  }
}
