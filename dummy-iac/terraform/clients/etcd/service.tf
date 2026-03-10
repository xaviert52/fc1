resource "aws_ecs_service" "etcd" {
  name            = "${var.project}-${var.environment}-etcd-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = aws_ecs_task_definition.etcd.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  network_configuration {
    subnets         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_groups = [aws_security_group.etcd.id]
  }

  service_registries {
    registry_arn = data.terraform_remote_state.vpc.outputs.etcd_service_discovery_arn
  }

  tags = {
    project     = var.project
    environment = var.environment
    service     = "etcd"
  }
}
