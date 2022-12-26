resource "aws_lb" "ecs" {
  name_prefix = "ecs"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.http.id]
  subnets = module.vpc.public_subnets
}

resource "aws_lb_target_group" "ecs" {
  port        = local.backend.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path = "/healthz"
    port = local.backend.port
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.ecs.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}
