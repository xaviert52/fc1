resource "aws_efs_file_system" "etcd" {
  creation_token = "pry-etcd-clean"

  encrypted = false

  tags = {
    project     = var.project
    environment = var.environment
    service     = "etcd"
  }
}

resource "aws_efs_mount_target" "etcd" {
  for_each = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)

  file_system_id  = aws_efs_file_system.etcd.id
  subnet_id       = each.value
  security_groups = [aws_security_group.etcd.id]
}