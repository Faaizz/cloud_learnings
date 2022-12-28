locals {
  account_id = data.aws_caller_identity.current.account_id

  vpc = {
    name = "websocket-chat-application"
    cidr = "172.16.0.0/16"
    azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
    private_subnets = {
      cidrs = ["172.16.10.0/24", "172.16.11.0/24"]
      names = ["172.16.10.0", "172.16.11.0"]
    }
    public_subnets = {
      cidrs = ["172.16.100.0/24", "172.16.101.0/24"]
      names = ["172.16.100.0", "172.16.101.0"]
    }
  }

  ecr = {
    repo_name = "websocket-chat-application"
    image_name = "backend"
  }

  frontend = {
    github = {
      repo_url = "https://github.com/Faaizz/simple_websocket_chatapp_frontend.git"
    }
  }

  backend = {
    port = 80

    cb = {
      project_name = "websocket-chat-application"
      role_name = "websocket-chat-application"
    }

    github = {
      repo_url = "https://github.com/Faaizz/simple_http_chatapp"
    }

      dynamodb = {
      name = "websocket-chat-application-backend-persistence"
    }

    api_gateway = {
      name = "websocket-chat-application-backend-api"
    }
  }

  ecs = {
    cluster_name = "websocket-chat-application-backend"

    task = {
      name = "backend"
      exec_role = {
        name = "backend-ecs-task-execution"
      }
      role = {
        name = "backend-ecs-task"
      }
      container = {
        name = "backend"
        image = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr.repo_name}:${local.ecr.image_name}"
        port_mappings = [
          {
            containerPort = local.backend.port
            hostPort = local.backend.port
          }
        ]
      }
    }

    service = {
      name = "backend"
    }
  }
}
