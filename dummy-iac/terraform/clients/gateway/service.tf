resource "aws_security_group" "gateway" {
  name        = "${var.project}-${var.environment}-gateway-sg"
  description = "Security Group for APISIX gateway"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "NLB to APISIX"
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    client_id   = var.client_id
  }
}

resource "aws_ecr_repository" "gateway" {
  name = "${var.project}-${var.environment}-gateway"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    project     = var.project
    environment = var.environment
    component   = "ecr"
    client_id   = var.client_id
  }
}

resource "aws_ecs_service" "gateway" {
  name            = "${var.project}-${var.environment}-gateway-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 200

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  enable_execute_command = true

  network_configuration {
    subnets         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_groups = [aws_security_group.gateway.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dns-gateway[0].arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway.arn
    container_name   = "gateway-container"
    container_port   = 9080
  }

  depends_on = [
    aws_lb_listener.gateway_tls_443
  ]

  tags = {
    project     = var.project
    environment = var.environment
    component   = "ecs-service"
    client_id   = var.client_id
  }
}

resource "aws_service_discovery_service" "dns-gateway" {
  count = var.enable_service_discovery ? 1 : 0

  name = "dns-gateway"

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
    Service     = "dns-gateway"
  }
}
