resource "aws_ecs_task_definition" "etcd" {
  family                   = "pry-etcd-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = data.terraform_remote_state.ecs.outputs.ecs_task_execution_role_arn
  task_role_arn      = data.terraform_remote_state.ecs.outputs.ecs_task_role_arn

  volume {
    name = "etcd-data"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.etcd.id
      root_directory = "/"
    }
  }

     container_definitions = jsonencode([
          {
               name      = "etcd"
               image     = "quay.io/coreos/etcd:v3.5.12"
               essential = true

               command = [
                    "etcd",
                    "--name=etcd-1",
                    "--data-dir=/etcd-data",

                    "--listen-client-urls=http://0.0.0.0:2379",
                    "--advertise-client-urls=http://etcd.pry.internal:2379",

                    "--listen-peer-urls=http://0.0.0.0:2380",
                    "--initial-advertise-peer-urls=http://etcd.pry.internal:2380",

                    "--initial-cluster=etcd-1=http://etcd.pry.internal:2380",
                    "--initial-cluster-state=new"
               ]

               mountPoints = [
                    {
                    sourceVolume  = "etcd-data"
                    containerPath = "/etcd-data"
                    readOnly      = false
                    }
               ]

               portMappings = [
                    {
                    containerPort = 2379
                    protocol      = "tcp"
                    }
               ]

               logConfiguration = {
                    logDriver = "awslogs"
                    options = {
                    awslogs-group         = aws_cloudwatch_log_group.etcd.name
                    awslogs-region        = var.aws_region
                    awslogs-stream-prefix = "etcd"
                    }
               }
          }
     ])
}