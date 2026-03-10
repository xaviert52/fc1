resource "aws_security_group" "etcd" {
  name        = "${var.project}-${var.environment}-etcd-sg"
  description = "Security group for etcd cluster (Zero Trust)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow EFS mounting only for etcd tasks"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true # <--- FIX: Solo recursos con este SG pueden montar el disco
  }

  ingress {
    description = "Allow APISIX Gateway to connect to etcd"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"

    # 1. ELIMINAMOS el cidr_blocks que permitía a toda la red 10.0.0.0/16
    # 2. AÑADIMOS el Security Group estricto del Gateway
    security_groups = [data.terraform_remote_state.gateway.outputs.gateway_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-etcd"
    Project     = var.project
    Environment = var.environment
  }
}
