# 1. Security Group: Solo acepta tráfico del Gateway (Zero Trust)
resource "aws_security_group" "client_zero" {
  name        = "pry-client-zero-sg"
  description = "SG for client-zero - Only allows Gateway"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
    description     = "Allow traffic from APISIX Gateway"
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

# 2. Registro en Cloud Map (DNS Interno)
resource "aws_service_discovery_service" "client_zero" {
  count = var.enable_service_discovery ? 1 : 0

  name = "dns-${var.client_id}" # Resultado: dns-client-zero.pry.internal

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

# 3. Servicio ECS (Sin Load Balancer, Con Service Registry)
resource "aws_ecs_service" "client_zero" {
  name            = "pry-client-zero-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.client_zero.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_groups = [aws_security_group.client_zero.id]
  }

  # Registro en Cloud Map
  service_registries {
    registry_arn = aws_service_discovery_service.client_zero[0].arn
  }

  tags = {
    project     = var.project
    environment = var.environment
    component   = "ecs-service"
    client_id   = var.client_id
  }
}

resource "aws_ecr_repository" "client_zero" {
  name                 = "pry-client-zero"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # Permite borrarlo si tiene imágenes (útil en sandbox)

  tags = {
    project     = var.project
    environment = var.environment
    component   = "ecr"
    client_id   = var.client_id
  }
}
