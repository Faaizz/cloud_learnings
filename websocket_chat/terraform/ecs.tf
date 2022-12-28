resource "aws_ecs_cluster" "backend" {
  name = local.ecs.cluster_name

  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "backend" {
  family = local.ecs.task.name 
  container_definitions = jsonencode([
    {
      name = local.ecs.task.container.name
      image = local.ecs.task.container.image
      essential = true
      portMappings = local.ecs.task.container.port_mappings
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group": "true"
          "awslogs-group": "awslogs-websocket-chatapp"
          "awslogs-region": "eu-central-1"
          "awslogs-stream-prefix": "awslogs-websocket-chatapp"
        }
      }
      cpu = 512
      environment = [
        {
          Name = "DB_TYPE"
          Value = "DYNAMODB"
        },
        {
          Name = "DYNAMODB_TABLE_NAME"
          Value = aws_dynamodb_table.main.id
        },
        {
          Name = "HTTP_PORT"
          Value = tostring(local.backend.port)
        }
      ]
    }
  ])
  task_role_arn = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.task_exec.arn
  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "backend" {
  name = local.ecs.service.name
  cluster = aws_ecs_cluster.backend.id
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count = 1

  network_configuration {
    subnets = module.vpc.public_subnets
    security_groups = [aws_security_group.http.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name = local.ecs.task.container.name
    container_port = local.backend.port
  }
}
